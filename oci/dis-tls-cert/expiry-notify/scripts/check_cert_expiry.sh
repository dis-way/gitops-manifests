#!/bin/bash

# Check Azure Key Vault for TLS certificates that are about to expire and post a
# summary to Slack. Silent when everything is healthy, unless NOTIFY_OK=true.
#
# Any failure is also reported to Slack, so a broken check is not mistaken for a
# clean bill of health. The one thing this cannot report is the job never running
# at all - that needs an external watcher on the CronJob.
#
# Reads certificate metadata only, never certificate or key material.

set -euo pipefail

: "${VAULT_NAME:?VAULT_NAME must be set, e.g. dis-tls-cert}"
: "${SLACK_WEBHOOK_URL:?SLACK_WEBHOOK_URL must be set}"

# Exported so the python steps below can read them.
export VAULT_NAME
export WARN_DAYS="${WARN_DAYS:-21}"
export NOTIFY_OK="${NOTIFY_OK:-false}"
export DRY_RUN="${DRY_RUN:-false}"
export CONTEXT="${CONTEXT:-}"
# Used to build the troubleshooting hints in the Slack message.
export NAMESPACE="${NAMESPACE:-dis-tls-cert}"
export CRONJOB_NAME="${CRONJOB_NAME:-dis-tls-cert-expiry-notify}"

# Post a failure notice to the same webhook. Never allowed to fail the script
# itself: if Slack is the thing that is broken, there is nothing left to try.
report_failure() {
    local summary="$1"
    local detail="${2:-}"

    echo "Reporting failure to Slack: ${summary}" >&2
    if [ "$DRY_RUN" = "true" ]; then
        echo "DRY_RUN=true, not posting the failure to Slack" >&2
        return 0
    fi

    FAILURE_SUMMARY="$summary" FAILURE_DETAIL="$detail" python3 - <<'PY' || \
        echo "Error: could not report the failure to Slack either" >&2
import json
import os
import urllib.request

text = (
    f":x: *TLS certificate expiry check failed* - vault `{os.environ['VAULT_NAME']}`\n"
    f"{os.environ['FAILURE_SUMMARY']}"
)
detail = os.environ["FAILURE_DETAIL"].strip()
if detail:
    text += "\n```" + detail[-500:] + "```"

namespace = os.environ["NAMESPACE"]
cronjob = os.environ["CRONJOB_NAME"]
text += (
    "\n*Troubleshoot*\n```"
    f"kubectl -n {namespace} get jobs\n"
    f"kubectl -n {namespace} logs job/<failed job>\n"
    f"kubectl -n {namespace} get externalsecret,secretstore\n"
    f"kubectl -n {namespace} create job --from=cronjob/{cronjob} expiry-check-manual"
    "```"
)

request = urllib.request.Request(
    os.environ["SLACK_WEBHOOK_URL"],
    data=json.dumps({"text": text}).encode(),
    headers={"Content-Type": "application/json"},
)
try:
    urllib.request.urlopen(request, timeout=30).read()
except Exception as error:  # noqa: BLE001 - last resort, keep the log readable
    raise SystemExit(f"Error: posting the failure to Slack failed: {error}")
PY
}

# AZURE_* are injected by the azure-workload-identity webhook because the pod
# carries the azure.workload.identity/use: "true" label.
if [ -z "${AZURE_CLIENT_ID:-}" ] || [ -z "${AZURE_TENANT_ID:-}" ] || [ -z "${AZURE_FEDERATED_TOKEN_FILE:-}" ]; then
    report_failure "Workload identity environment is missing - is the pod labelled \`azure.workload.identity/use=true\`?"
    exit 1
fi

# --allow-no-subscriptions is required: the identity holds vault data-plane roles
# only, no subscription role.
echo "Logging in as client ${AZURE_CLIENT_ID}"
if ! az login --service-principal \
    --username "${AZURE_CLIENT_ID}" \
    --tenant "${AZURE_TENANT_ID}" \
    --federated-token "$(cat "${AZURE_FEDERATED_TOKEN_FILE}")" \
    --allow-no-subscriptions \
    --only-show-errors \
    --output none 2>/tmp/az-login-error.log; then
    cat /tmp/az-login-error.log >&2
    report_failure "\`az login\` failed for client \`${AZURE_CLIENT_ID}\` - check the federated credential and its subject." \
        "$(cat /tmp/az-login-error.log)"
    exit 1
fi

# az pages through the vault for us and returns metadata only.
if ! az keyvault certificate list \
    --vault-name "$VAULT_NAME" \
    --only-show-errors \
    --output json > /tmp/certs.json 2>/tmp/az-list-error.log; then
    cat /tmp/az-list-error.log >&2
    report_failure "Listing certificates in \`${VAULT_NAME}\` failed - check the vault firewall and the identity's Key Vault role." \
        "$(cat /tmp/az-list-error.log)"
    exit 1
fi

if ! python3 - <<'PY' 2>/tmp/report-error.log
import datetime as dt
import json
import os
import sys
import urllib.error
import urllib.request

vault = os.environ["VAULT_NAME"]
warn_days = int(os.environ["WARN_DAYS"])
context = os.environ["CONTEXT"]

with open("/tmp/certs.json") as f:
    certs = json.load(f)

# An empty list means the identity lost access or the vault was emptied. Either
# way it is not an all-clear, so fail loudly instead of reporting silence.
if not certs:
    sys.exit(f"Error: no certificates returned from {vault} - refusing to report all-clear")

print(f"Found {len(certs)} certificate(s) in {vault}")

now = dt.datetime.now(dt.timezone.utc)
expiring = []
no_expiry = []

for cert in certs:
    attributes = cert.get("attributes") or {}
    if attributes.get("enabled") is False:
        continue
    name = cert.get("name") or cert.get("id", "").rsplit("/", 1)[-1]
    expires = attributes.get("expires")
    if not expires:
        no_expiry.append(name)
        continue
    seconds_left = (dt.datetime.fromisoformat(expires) - now).total_seconds()
    if seconds_left < warn_days * 86400:
        expiring.append((seconds_left, name, expires[:10]))

expiring.sort()
suffix = f" ({context})" if context else ""

if not expiring and not no_expiry:
    print(f"OK: no certificate in {vault} expires within {warn_days} days")
    if os.environ["NOTIFY_OK"] != "true":
        sys.exit(0)
    text = (
        f":white_check_mark: *TLS certificates OK* - none of the {len(certs)} "
        f"certificates in `{vault}`{suffix} expire within {warn_days} days"
    )
else:
    lines = [f":warning: *TLS certificates expiring soon* - vault `{vault}`{suffix}"]
    for seconds_left, name, expiry_date in expiring:
        if seconds_left < 0:
            days_ago = int(-seconds_left // 86400)
            lines.append(f":rotating_light: `{name}` *expired* {days_ago} days ago ({expiry_date})")
            print(f"Expired: {name} {days_ago} days ago ({expiry_date})")
        else:
            days_left = int(seconds_left // 86400)
            lines.append(f"- `{name}` expires in {days_left} days ({expiry_date})")
            print(f"Expiring: {name} in {days_left} days ({expiry_date})")
    if no_expiry:
        lines.append(f":grey_question: no expiry set, not monitored: `{', '.join(no_expiry)}`")
        print("No expiry attribute: " + ", ".join(no_expiry))

    namespace = os.environ["NAMESPACE"]
    lines.append(
        "*Troubleshoot* - cert-manager renews 30 days before expiry and the `PushSecret` "
        "copies the result to the vault within the hour. A name with no `Certificate` here "
        "is *not* renewed automatically and needs a new certificate."
    )
    lines.append(
        "```"
        f"kubectl -n {namespace} get certificate,pushsecret\n"
        f"kubectl -n {namespace} describe certificate <name>"
        "```"
    )
    text = "\n".join(lines)

if os.environ["DRY_RUN"] == "true":
    print("DRY_RUN=true, not posting to Slack. Message would be:")
    print(text)
    sys.exit(0)

request = urllib.request.Request(
    os.environ["SLACK_WEBHOOK_URL"],
    data=json.dumps({"text": text}).encode(),
    headers={"Content-Type": "application/json"},
)
try:
    with urllib.request.urlopen(request, timeout=30) as response:
        body = response.read().decode().strip()
except urllib.error.HTTPError as error:
    sys.exit(f"Error: Slack webhook returned HTTP {error.code}: {error.read().decode().strip()}")
except urllib.error.URLError as error:
    sys.exit(f"Error: could not reach Slack webhook: {error.reason}")

print(f"Posted expiry report to Slack ({body})")
PY
then
    cat /tmp/report-error.log >&2
    report_failure "Building or posting the expiry report failed." "$(cat /tmp/report-error.log)"
    exit 1
fi

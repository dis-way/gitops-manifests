# dis-tls-cert

Issues TLS certificates with cert-manager and pushes them to the `dis-tls-cert` Azure Key Vault for Azure services to consume.

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, workload identity ServiceAccount, `SecretStore`, EAB secrets, `ClusterIssuer`s, and `expiry-notify` |
| `certs` | One `Certificate` + `PushSecret` pair per domain |
| `expiry-notify` | Weekly `CronJob` that posts Key Vault certificates nearing expiry to Slack — pulled in by `base` |

## Variables

None. No layer in this package uses Flux variable substitution — the only secret the
`expiry-notify` layer needs is read from Key Vault with an `ExternalSecret`.

## Expiry notifications

`expiry-notify` reads certificate *metadata* from the Key Vault every Monday and reports anything expiring inside
`WARN_DAYS`, anything already expired, and any certificate with no expiry attribute set. It posts nothing when
everything is healthy unless `NOTIFY_OK` is set to `true` on the CronJob.

It reads the vault rather than the cluster's `Certificate` resources on purpose: the vault is what Azure services
actually consume, so this also catches a certificate whose `PushSecret` stopped working, and certificates in the vault
that no `Certificate` resource manages.

### Slack webhook

The webhook URL lives in the same Key Vault and is synced into the cluster by an `ExternalSecret` through the existing
`dis-tls-cert-store`, so it never passes through git or Flux substitution vars. The identity already holds Key Vault
Secrets Officer, so no new role assignment is needed — but the secret has to be created once by hand:

```sh
az keyvault secret set \
  --vault-name dis-tls-cert \
  --name cert-expiry-slack-webhook-url \
  --value "https://hooks.slack.com/services/..."
```

The job mounts it as `SLACK_WEBHOOK_URL` from the `dis-tls-cert-expiry-slack-webhook` Secret. If the `ExternalSecret`
has not synced, the pod will not start and the CronJob reports a failure — which is the intended behaviour.

### When the check itself fails

A failed check posts a `:x:` message to the same channel with the reason attached, so a broken check is not mistaken
for a clean bill of health. Covered: missing workload identity environment, `az login` failure, a denied or
unreachable vault, and a vault that returns zero certificates.

Two failures cannot be self-reported, by construction:

- **Slack is unreachable or the webhook was revoked.** The script logs `could not report the failure to Slack either`
  and exits non-zero, but nothing reaches the channel. Rotating the webhook without updating the vault secret lands
  here.
- **The job never runs at all** — not deployed, suspended, deleted, image pull failure, or unschedulable. No code of
  ours executes, so nothing can report.

Catching those needs a watcher outside this job, e.g. a Grafana alert on
`kube_cronjob_status_last_successful_time{cronjob="dis-tls-cert-expiry-notify"}` going stale (kube-state-metrics is
scraped into Azure Managed Prometheus on the admin clusters). Until that exists, a healthy week and a dead job look
the same in Slack — setting `NOTIFY_OK` to `"true"` on the CronJob at least turns silence into a weekly all-clear.

The job reuses the `dis-tls-cert-kv-uami` ServiceAccount, so it needs no new Azure role assignment — but a workload
identity federated credential only exists for `admin-prod-aks`, and `base` is only deployed there. If `base` is ever
rolled out to another cluster, add a federated credential for
`system:serviceaccount:dis-tls-cert:dis-tls-cert-kv-uami` on that cluster's OIDC issuer first, or the job will fail
every week — and since failures are reported to Slack, it will say so in the channel.

The default of 21 days is deliberate: cert-manager renews 30 days before expiry, so a 30-day threshold would fire on
every certificate the moment renewal comes due. 21 days leaves room for renewal plus the hourly `PushSecret` refresh,
while still giving three weeks of warning.

Verify the message without posting it:

```sh
kubectl -n dis-tls-cert create job --from=cronjob/dis-tls-cert-expiry-notify expiry-check-manual
kubectl -n dis-tls-cert logs job/expiry-check-manual
```

## Add a certificate

### Prerequisites

Before creating a new certificate, add a CNAME record for ACME DNS-01 challenge validation:

```
_acme-challenge.<domain>. 300 IN CNAME _acme-challenge.<domain>.acme.altinn.cloud.
```

Example for `af.tt02.altinn.no`:
```
_acme-challenge.af.tt02.altinn.no. 300 IN CNAME _acme-challenge.af.tt02.altinn.no.acme.altinn.cloud.
```

### Create the certificate

```bash
./add-cert.sh <domain>
```

## Inspect certs in cluster
### set variables
```sh
NAMESPACE=dis-tls-cert
SECRET_NAME=af-tt02-altinn-no
```

### 1. Dump and inspect the certificate (human-readable)
```sh
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.crt}' \
| base64 --decode \
| openssl x509 -noout -text
```
### 2. Check certificate expiry dates
```sh
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.crt}' \
| base64 --decode \
| openssl x509 -noout -dates
```
### 3. Inspect Subject Alternative Names (SANs)
```sh
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.crt}' \
| base64 --decode \
| openssl x509 -noout -ext subjectAltName
```
### 4. Inspect the private key (sanity check)
⚠️ Be careful — this exposes private key material.
```sh
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.key}' \
| base64 --decode \
| openssl rsa -noout -check
```
### 5. Verify certificate and private key match
```sh
# Certificate modulus
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.crt}' \
| base64 --decode \
| openssl x509 -noout -modulus \
| openssl md5

# Private key modulus
kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" \
  -o jsonpath='{.data.tls\.key}' \
| base64 --decode \
| openssl rsa -noout -modulus \
| openssl md5
```

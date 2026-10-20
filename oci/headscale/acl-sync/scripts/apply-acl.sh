#!/bin/sh
# Applies the ACL policy from Git (Key Vault secret headscale-acl, synced to the
# Secret headscale-acl in flux-system) to Headscale. Git wins: an edit made in
# Headplane or with the CLI is logged as a diff and overwritten.
set -eu

headscale() {
  kubectl exec -i -n headscale deploy/headscale -c headscale -- headscale "$@"
}

kubectl get secret -n flux-system headscale-acl -o jsonpath='{.data.acl\.hujson}' |
  base64 -d >/tmp/acl.hujson
if [ ! -s /tmp/acl.hujson ]; then
  echo "ERROR: Secret flux-system/headscale-acl has no acl.hujson" >&2
  exit 1
fi

# policy get prints the stored policy followed by a newline.
{ cat /tmp/acl.hujson; echo; } >/tmp/want.hujson
headscale policy get >/tmp/live.hujson 2>/dev/null || : >/tmp/live.hujson

if cmp -s /tmp/live.hujson /tmp/want.hujson; then
  echo "policy in sync"
  exit 0
fi

echo "WARNING: live policy differs from Git, overwriting"
diff -u /tmp/live.hujson /tmp/want.hujson || true

# Checks against the live users and nodes. set rejects an invalid policy too,
# but check also runs the policy's tests blocks.
headscale policy check -f /dev/stdin </tmp/acl.hujson
headscale policy set -f /dev/stdin </tmp/acl.hujson
echo "policy applied"

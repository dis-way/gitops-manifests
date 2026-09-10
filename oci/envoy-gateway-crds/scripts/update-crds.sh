#!/usr/bin/env bash

# Vendors the rendered Envoy Gateway CRDs from the upstream release asset into
# oci/envoy-gateway-crds/base/envoy-gateway-crds.yaml.
#
# The rendered CRDs are only published as a GitHub release asset - the copies in
# the upstream git tree are Helm templates and cannot be consumed by kustomize.
# The gateway-crds-helm chart cannot be used either: Helm embeds the whole chart
# in the release Secret, which exceeds the 1 MiB Kubernetes Secret limit.
#
# The version below is maintained by Renovate; this script is run automatically
# on Renovate PRs by .github/workflows/refresh-envoy-gateway-crds.yml.
#
# Usage:
#   scripts/update-crds.sh                  refresh the vendored manifest
#   scripts/update-crds.sh --check          verify the vendored manifest matches
#                                           upstream for the pinned version
#   scripts/update-crds.sh --version v1.8.4 one-off override, for testing

set -euo pipefail

# renovate: datasource=github-releases packageName=envoyproxy/gateway extractVersion=^v(?<version>.+)$
ENVOY_GATEWAY_VERSION="1.9.1"

# The asset must contain exactly these 8 CRDs and nothing else.
EXPECTED_CRD_COUNT=8
# Smallest plausible asset; guards against a truncated download or an error page.
MIN_BYTES=1000000

check_only=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)   check_only=true; shift ;;
    --version) ENVOY_GATEWAY_VERSION="${2#v}"; shift 2 ;;
    -h|--help) sed -n '3,23p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

fail() { echo "Error: $*" >&2; exit 1; }

# grep -c only: never "grep -q" combined with "-v". Homebrew's ugrep shadows
# grep on some developer machines and returns 1 from "grep -qv" even when
# non-matching lines exist, which silently disables that kind of guard.
count() { grep -c "$1" "$2" || true; }

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# The digest GitHub records for the release asset, read from api.github.com.
# The asset bytes are served from release-assets.githubusercontent.com, so this
# is an independent channel: it catches a corrupted, truncated or tampered
# download without us having to compute the expected value ourselves.
# Prints "sha256:..." on success, "NONE" if the asset predates the digest field,
# and nothing if the API could not be read.
api_digest() {
  local api="https://api.github.com/repos/envoyproxy/gateway/releases/tags/${TAG}"
  local token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  # No arrays: "${arr[@]}" on an empty array is an unbound variable under
  # "set -u" in the bash 3.2 that macOS still ships.
  if [ -n "${token}" ]; then
    curl --fail --location --silent --show-error --retry 3 \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${token}" "${api}" 2>/dev/null
  else
    curl --fail --location --silent --show-error --retry 3 \
      -H "Accept: application/vnd.github+json" "${api}" 2>/dev/null
  fi \
    | python3 -c '
import json, sys
try:
    assets = json.load(sys.stdin).get("assets", [])
except Exception:
    sys.exit(1)
match = [a for a in assets if a.get("name") == "envoy-gateway-crds.yaml"]
if not match:
    sys.exit(1)
print(match[0].get("digest") or "NONE")
'
}

TAG="v${ENVOY_GATEWAY_VERSION}"
BASE_DIR="$(cd "$(dirname "$0")/../base" && pwd)"
TARGET="${BASE_DIR}/envoy-gateway-crds.yaml"
URL="https://github.com/envoyproxy/gateway/releases/download/${TAG}/envoy-gateway-crds.yaml"

# Explicit templates so this works regardless of TMPDIR, and keeps the files on
# the same filesystem as the target so the final move is atomic.
DOWNLOAD="$(mktemp "${BASE_DIR}/.download.XXXXXX")"
COMPOSED="$(mktemp "${BASE_DIR}/.composed.XXXXXX")"
trap 'rm -f "${DOWNLOAD}" "${COMPOSED}"' EXIT

echo "Downloading ${URL}"
curl --fail --location --silent --show-error --retry 3 "${URL}" --output "${DOWNLOAD}" \
  || fail "download failed - does release ${TAG} publish an envoy-gateway-crds.yaml asset?"

# --- integrity --------------------------------------------------------------
command -v python3 >/dev/null 2>&1 || fail "python3 is required to read the asset digest from the GitHub API"

ACTUAL_DIGEST="sha256:$(sha256 "${DOWNLOAD}")"
API_DIGEST="$(api_digest || true)"

if [ -z "${API_DIGEST}" ]; then
  fail "could not read the release asset digest from the GitHub API for ${TAG}.
       This check is not skipped on failure. If you are being rate limited, set
       GH_TOKEN (or GITHUB_TOKEN) to a token with public read access and retry."
elif [ "${API_DIGEST}" = "NONE" ]; then
  echo "Warning: GitHub records no digest for the ${TAG} asset; relying on the structural checks only." >&2
elif [ "${API_DIGEST}" != "${ACTUAL_DIGEST}" ]; then
  fail "digest mismatch for ${TAG} - refusing to vendor these bytes.
       GitHub API: ${API_DIGEST}
       downloaded: ${ACTUAL_DIGEST}"
else
  echo "Digest verified against the GitHub API: ${ACTUAL_DIGEST}"
fi

# --- validation -------------------------------------------------------------
# Shape checks, on top of the digest verification above. Neither can prove the
# release itself is trustworthy - a malicious upstream release would carry a
# matching digest. That is upstream trust, and unchanged from using the chart.
SIZE="$(wc -c < "${DOWNLOAD}" | tr -d ' ')"
if [ "${SIZE}" -lt "${MIN_BYTES}" ]; then
  fail "asset is only ${SIZE} bytes (expected >= ${MIN_BYTES}); truncated download or an error page"
fi

if grep -q '{{' "${DOWNLOAD}"; then
  fail "asset contains Helm template markers - upstream changed the asset, do not vendor it"
fi

# Every top-level document must be an apiextensions CRD: comparing the total
# count of column-0 "kind:"/"apiVersion:" lines against the CRD count rejects
# any extra object smuggled into the file.
KIND_TOTAL="$(count '^kind: ' "${DOWNLOAD}")"
CRD_COUNT="$(count '^kind: CustomResourceDefinition$' "${DOWNLOAD}")"
API_TOTAL="$(count '^apiVersion: ' "${DOWNLOAD}")"
API_CRD="$(count '^apiVersion: apiextensions.k8s.io/v1$' "${DOWNLOAD}")"
GROUP_COUNT="$(count '^  group: gateway.envoyproxy.io$' "${DOWNLOAD}")"

if [ "${CRD_COUNT}" -ne "${EXPECTED_CRD_COUNT}" ]; then
  fail "expected ${EXPECTED_CRD_COUNT} CustomResourceDefinitions, found ${CRD_COUNT}"
fi

if [ "${KIND_TOTAL}" -ne "${CRD_COUNT}" ]; then
  fail "asset has ${KIND_TOTAL} top-level objects but only ${CRD_COUNT} CRDs - something other than a CRD is in the file"
fi

if [ "${API_TOTAL}" -ne "${EXPECTED_CRD_COUNT}" ] || [ "${API_CRD}" -ne "${EXPECTED_CRD_COUNT}" ]; then
  fail "expected ${EXPECTED_CRD_COUNT} apiextensions.k8s.io/v1 documents, found ${API_CRD} of ${API_TOTAL}"
fi

if [ "${GROUP_COUNT}" -ne "${EXPECTED_CRD_COUNT}" ]; then
  fail "expected ${EXPECTED_CRD_COUNT} CRDs in group gateway.envoyproxy.io, found ${GROUP_COUNT} - the asset may now include Gateway API CRDs, which the gateway-api package owns"
fi

echo "Validated ${TAG}: ${SIZE} bytes, ${CRD_COUNT} CRDs"

# --- compose ----------------------------------------------------------------
{
  echo "# Envoy Gateway CRDs ${TAG}"
  echo "# Generated file - do not edit."
  echo "# Source: ${URL}"
  echo "# Digest: ${ACTUAL_DIGEST} (verified against the GitHub release asset API)"
  echo "# Refresh with: oci/envoy-gateway-crds/scripts/update-crds.sh"
  cat "${DOWNLOAD}"
} > "${COMPOSED}"

if [ "${check_only}" = true ]; then
  [ -f "${TARGET}" ] || fail "${TARGET} does not exist; run this script without --check"
  if cmp -s "${COMPOSED}" "${TARGET}"; then
    echo "OK: vendored manifest matches upstream ${TAG}"
    exit 0
  fi
  echo >&2
  echo "Error: the vendored manifest does not match upstream ${TAG}." >&2
  echo "       Either it was edited by hand, or the upstream release asset changed" >&2
  echo "       after it was vendored. Review the difference before accepting it:" >&2
  echo "         vendored: sha256 $(sha256 "${TARGET}")" >&2
  echo "         upstream: sha256 $(sha256 "${COMPOSED}")" >&2
  exit 1
fi

if [ -f "${TARGET}" ] && cmp -s "${COMPOSED}" "${TARGET}"; then
  echo "Already up to date (${TAG})"
  exit 0
fi

mv "${COMPOSED}" "${TARGET}"
echo "Wrote ${TARGET} (${CRD_COUNT} CRDs, ${TAG})"

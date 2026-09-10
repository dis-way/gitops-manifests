#!/bin/bash

# Refreshes the vendored Envoy Gateway CRDs from the upstream release asset.
#
# The rendered CRDs are only published as a GitHub release asset - the copies in
# the upstream git tree are Helm templates and cannot be consumed by kustomize.
# The version below is maintained by Renovate; this script is run automatically
# on Renovate PRs by .github/workflows/refresh-envoy-gateway-crds.yml.

set -euo pipefail

# renovate: datasource=github-releases packageName=envoyproxy/gateway extractVersion=^v(?<version>.+)$
ENVOY_GATEWAY_VERSION="1.9.1"

EXPECTED_CRD_COUNT=8

TAG="v${ENVOY_GATEWAY_VERSION}"
BASE_DIR="$(cd "$(dirname "$0")/../base" && pwd)"
TARGET="${BASE_DIR}/envoy-gateway-crds.yaml"
URL="https://github.com/envoyproxy/gateway/releases/download/${TAG}/envoy-gateway-crds.yaml"

# Explicit template so this works regardless of TMPDIR, and keeps the download
# on the same filesystem as the target.
TMP="$(mktemp "${BASE_DIR}/.envoy-gateway-crds.yaml.XXXXXX")"
trap 'rm -f "${TMP}"' EXIT

echo "Downloading ${URL}"
curl --fail --location --silent --show-error --retry 3 "${URL}" --output "${TMP}"

# The release asset is rendered, so no Helm template markers should survive.
if grep -q '{{' "${TMP}"; then
  echo "Error: downloaded asset contains Helm template markers" >&2
  exit 1
fi

# "|| true" so a zero count reports the error below instead of tripping "set -e".
CRD_COUNT="$(grep -c '^kind: CustomResourceDefinition' "${TMP}" || true)"
if [ "${CRD_COUNT}" -ne "${EXPECTED_CRD_COUNT}" ]; then
  echo "Error: expected ${EXPECTED_CRD_COUNT} CustomResourceDefinitions, found ${CRD_COUNT}" >&2
  exit 1
fi

if grep '^  name: ' "${TMP}" | grep -qv '\.gateway\.envoyproxy\.io$'; then
  echo "Error: asset contains CRDs outside the gateway.envoyproxy.io group" >&2
  exit 1
fi

{
  echo "# Envoy Gateway CRDs ${TAG}"
  echo "# Generated file - do not edit."
  echo "# Source: ${URL}"
  echo "# Refresh with: oci/envoy-gateway-crds/scripts/update-crds.sh"
  cat "${TMP}"
} > "${TARGET}"

echo "Wrote ${TARGET} (${CRD_COUNT} CRDs, ${TAG})"

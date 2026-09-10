#!/usr/bin/env bash

# Renders the envoy-gateway-crds package and asserts it produces the expected
# CRDs. Shared by the verify and refresh jobs of refresh-envoy-gateway-crds.yml.
# Uses the same kustomize/kubectl fallback as
# dis-way/actions/.github/workflows/kustomize-diff.yml.

set -euo pipefail

EXPECTED_CRD_COUNT=8

build() {
  if command -v kustomize >/dev/null 2>&1; then
    kustomize build "$1"
  elif command -v kubectl >/dev/null 2>&1; then
    kubectl kustomize "$1"
  else
    echo "Error: neither 'kustomize' nor 'kubectl' found in PATH." >&2
    exit 1
  fi
}

for path in oci/envoy-gateway-crds oci/envoy-gateway-crds/multitenancy; do
  crds="$(build "${path}" | grep -c '^kind: CustomResourceDefinition$' || true)"
  echo "${path} -> ${crds} CRDs"
  if [ "${crds}" -ne "${EXPECTED_CRD_COUNT}" ]; then
    echo "::error::expected ${EXPECTED_CRD_COUNT} CRDs from ${path}, got ${crds}" >&2
    exit 1
  fi
done

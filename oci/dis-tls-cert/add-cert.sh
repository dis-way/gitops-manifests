#!/bin/bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: $0 <domain>"
  echo "Example: $0 af.tt02.altinn.no"
  exit 1
fi

DOMAIN="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="${DOMAIN//./-}"

CERTS_DIR="${SCRIPT_DIR}/certs"
CERT_FILE="${CERTS_DIR}/${DOMAIN}.yaml"
PUSH_FILE="${CERTS_DIR}/${DOMAIN}-push.yaml"
KUSTOMIZATION_FILE="${CERTS_DIR}/kustomization.yaml"

# Available ClusterIssuers
ISSUERS=(
  "letsencrypt-dis-tls-cert-staging"
  "letsencrypt-dis-tls-cert"
  "zerossl-dis-tls-cert"
  "digicert-dis-tls-cert"
)

echo "Select ClusterIssuer:"
for i in "${!ISSUERS[@]}"; do
  echo "  $((i+1))) ${ISSUERS[$i]}"
done
read -rp "Choice [1-${#ISSUERS[@]}]: " choice

if ! [[ "$choice" =~ ^[1-${#ISSUERS[@]}]$ ]]; then
  echo "Invalid choice"
  exit 1
fi
ISSUER="${ISSUERS[$((choice-1))]}"

# Check if files already exist
if [ -f "$CERT_FILE" ]; then
  echo "Error: ${CERT_FILE} already exists"
  exit 1
fi

if [ -f "$PUSH_FILE" ]; then
  echo "Error: ${PUSH_FILE} already exists"
  exit 1
fi

# Generate Certificate resource
cat > "$CERT_FILE" <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${NAME}
  namespace: dis-tls-cert
spec:
  secretName: ${NAME}
  issuerRef:
    name: ${ISSUER}
    kind: ClusterIssuer
  dnsNames:
    - ${DOMAIN}
EOF

echo "Created ${CERT_FILE}"

# Generate PushSecret resource
cat > "$PUSH_FILE" <<EOF
apiVersion: external-secrets.io/v1alpha1
kind: PushSecret
metadata:
  name: ${NAME}-push
  namespace: dis-tls-cert
spec:
  refreshInterval: 1h
  secretStoreRefs:
    - name: dis-tls-cert-store
      kind: SecretStore
  selector:
    secret:
      name: ${NAME}
  template:
    engineVersion: v2
    type: kubernetes.io/tls
    data:
      tls.crt: '{{ index . "tls.crt" }}'
      tls.key: '{{ index . "tls.key" }}'
      pfx_bundle: '{{ fullPemToPkcs12 (index . "tls.crt") (index . "tls.key") | b64dec }}'
  data:
    # PEM format for Kubernetes clusters
    - match:
        secretKey: tls.crt
        remoteRef:
          remoteKey: ${NAME}-crt
    - match:
        secretKey: tls.key
        remoteRef:
          remoteKey: ${NAME}-key
    # PFX format for Azure services
    - match:
        secretKey: pfx_bundle
        remoteRef:
          remoteKey: cert/${NAME}
EOF

echo "Created ${PUSH_FILE}"

# Add to kustomization.yaml
if grep -q "^  - ${DOMAIN}.yaml$" "$KUSTOMIZATION_FILE"; then
  echo "Already in kustomization.yaml: ${DOMAIN}.yaml"
else
  sed -i'' -e "/^resources:$/a\\
  - ${DOMAIN}.yaml" "$KUSTOMIZATION_FILE"
  echo "Added ${DOMAIN}.yaml to kustomization.yaml"
fi

if grep -q "^  - ${DOMAIN}-push.yaml$" "$KUSTOMIZATION_FILE"; then
  echo "Already in kustomization.yaml: ${DOMAIN}-push.yaml"
else
  sed -i'' -e "/^  - ${DOMAIN}.yaml$/a\\
  - ${DOMAIN}-push.yaml" "$KUSTOMIZATION_FILE"
  echo "Added ${DOMAIN}-push.yaml to kustomization.yaml"
fi

echo "Done! Certificate for ${DOMAIN} using ${ISSUER} is ready."

# Verify all files are in kustomization.yaml
FILES=$(find "$CERTS_DIR" -maxdepth 1 -name "*.yaml" ! -name "kustomization.yaml" -exec basename {} \; | sort)
RESOURCES=$(grep -E "^  - .+\.yaml$" "$KUSTOMIZATION_FILE" | sed 's/^  - //' | sort)

MISSING=()
for file in $FILES; do
  if ! echo "$RESOURCES" | grep -qx "$file"; then
    MISSING+=("$file")
  fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "Verified: all files are in kustomization.yaml"
else
  echo "Warning - missing from kustomization.yaml:"
  for file in "${MISSING[@]}"; do
    echo "  - $file"
  done
fi

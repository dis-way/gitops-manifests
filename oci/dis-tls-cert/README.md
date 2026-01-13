# dis-tls-cert

## Add a certificate

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

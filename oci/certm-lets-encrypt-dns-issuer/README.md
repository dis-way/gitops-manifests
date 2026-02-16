# certm-lets-encrypt-dns-issuer

LetsEncrypt DNS ClusterIssuers and wildcard certificate for DIS.

## Resources

- `letsencrypt-staging` - ClusterIssuer for Let's Encrypt staging environment
- `letsencrypt-production` - ClusterIssuer for Let's Encrypt production environment
- `wildcard-tls` - Certificate for wildcard and apex DNS names (namespace: `traefik`)

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AZURE_DNS_ZONE_NAME` | - | Yes | DNS zone name to request certificates for |
| `AZURE_RESOURCE_GROUP` | - | Yes | Azure resource group that owns the DNS zone |
| `AZURE_SUBSCRIPTION_ID` | - | Yes | Azure subscription ID for DNS zone management |
| `IDENTITY_CLIENT_ID` | - | Yes | Managed identity client ID used for DNS01 challenge |

## Paths

| Path | Description |
|------|-------------|
| `./base` | Core resources (ClusterIssuers + wildcard Certificate) |
| `./apps` | Alias for `./base` |
| `./multitenancy` | Alias for `./base` |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./base
  postBuild:
    substitute:
      AZURE_DNS_ZONE_NAME: "example.com"
      AZURE_RESOURCE_GROUP: "dns-rg"
      AZURE_SUBSCRIPTION_ID: "00000000-0000-0000-0000-000000000000"
      IDENTITY_CLIENT_ID: "11111111-1111-1111-1111-111111111111"
```

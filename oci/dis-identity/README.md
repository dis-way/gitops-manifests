# dis-identity

Deploys the DIS Identity operator via Flux `OCIRepository` + `Kustomization`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISID_ISSUER_URL` | `""` | Yes | Issuer URL used by the DIS Identity operator |
| `DISID_TARGET_RESOURCE_GROUP` | `""` | Yes | Azure resource group containing target identity resources |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  # Use ./base to keep resources in flux-system, or ./multitenancy for platform-system
  path: ./multitenancy
  postBuild:
    substitute:
      DISID_ISSUER_URL: "https://issuer.example.com"
      DISID_TARGET_RESOURCE_GROUP: "dis-identity-rg"
```

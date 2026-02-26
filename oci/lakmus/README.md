# Lakmus

Deploys the Lakmus service for automated API testing and health checks.

## Resources

- `lakmus-system` Namespace
- `lakmus-config` OCIRepository (oci://altinncr.azurecr.io/dis/kustomize/lakmus)
- `lakmus-config` Kustomization (Flux)

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AZURE_SUBSCRIPTION_ID` | - | Yes | Azure Subscription ID |
| `LAKMUS_WORKLOAD_IDENTITY_CLIENT_ID` | - | Yes | Client ID of the Azure Workload Identity used by Lakmus |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./
  postBuild:
    substitute:
      AZURE_SUBSCRIPTION_ID: "00000000-0000-0000-0000-000000000000"
      LAKMUS_WORKLOAD_IDENTITY_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
```

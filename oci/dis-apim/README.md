# dis-apim

Deploys the DIS APIM operator via Flux `OCIRepository` + `Kustomization`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISAPIM_SUBSCRIPTION_ID` | `""` | Yes | Azure subscription ID used by the operator |
| `DISAPIM_RESOURCE_GROUP` | `""` | Yes | Azure resource group containing the APIM instance |
| `DISAPIM_APIM_SERVICE_NAME` | `""` | Yes | Azure API Management service name |
| `DISAPIM_DEFAULT_LOGGER_ID` | `""` | Yes | Default logger ID configured in APIM |
| `DISAPIM_NAMESPACE_SUFFIX` | `""` | No | Namespace suffix used by the operator |
| `DISAPIM_WORKLOAD_IDENTITY_CLIENT_ID` | `""` | Yes | Workload identity client ID used by the operator |
| `DISAPIM_TARGET_NAMESPACE` | `dis-apim-operator-system` | No | Target namespace for the operator workload |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  # Use ./base to keep resources in flux-system, or ./multitenancy for platform-system
  path: ./multitenancy
  postBuild:
    substitute:
      DISAPIM_SUBSCRIPTION_ID: "00000000-0000-0000-0000-000000000000"
      DISAPIM_RESOURCE_GROUP: "dis-rg"
      DISAPIM_APIM_SERVICE_NAME: "dis-apim"
      DISAPIM_DEFAULT_LOGGER_ID: "logger-id"
      DISAPIM_NAMESPACE_SUFFIX: "dev"
      DISAPIM_WORKLOAD_IDENTITY_CLIENT_ID: "11111111-1111-1111-1111-111111111111"
      # Optional
      DISAPIM_TARGET_NAMESPACE: "dis-apim-operator-system"
```

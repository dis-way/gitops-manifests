# DIS Vault Operator

Deploys the DIS Vault Operator for managing Azure Key Vault resources for DIS applications.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISVAULT_AZURE_SUBSCRIPTION_ID` | - | Yes | Azure subscription ID used for managed vault resources |
| `DISVAULT_RESOURCE_GROUP` | - | Yes | Azure resource group where managed vault resources are created |
| `DISVAULT_AZURE_TENANT_ID` | - | Yes | Azure tenant ID used by the operator |
| `DISVAULT_LOCATION` | - | Yes | Azure location for managed vault resources |
| `DISVAULT_ENV` | - | Yes | DIS environment identifier used in generated naming |
| `DISVAULT_AKS_SUBNET_IDS` | - | Yes | Comma-separated AKS subnet ARM IDs allowed to reach managed vaults |

## Layers

| Path | Description |
|------|-------------|
| `.` | Flux `OCIRepository` and `Kustomization` for deploying the operator from `flux-system` |

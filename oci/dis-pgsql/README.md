# DIS PostgreSQL Operator

Deploys the DIS PostgreSQL Operator for managing PostgreSQL database resources in Azure.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISPG_AZURE_SUBSCRIPTION_ID` | - | Yes | Azure Subscription ID where PostgreSQL resources reside |
| `DISPG_AZURE_TENANT_ID` | - | Yes | Azure Tenant ID for authentication |
| `DISPG_DB_RESOURCE_GROUP` | - | Yes | Azure Resource Group containing PostgreSQL databases |
| `DISPG_DB_VNET_NAME` | - | Yes | Virtual network name for the database subnet |
| `DISPG_AKS_VNET_NAME` | - | Yes | Virtual network name for the AKS cluster |
| `DISPG_AKS_RESOURCE_GROUP` | - | Yes | Azure Resource Group containing the AKS cluster |
| `DISPG_WORKLOAD_IDENTITY_CLIENT_ID` | - | Yes | Client ID of the Azure Workload Identity used by the operator |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./
  postBuild:
    substitute:
      DISPG_AZURE_SUBSCRIPTION_ID: "00000000-0000-0000-0000-000000000000"
      DISPG_AZURE_TENANT_ID: "00000000-0000-0000-0000-000000000000"
      DISPG_DB_RESOURCE_GROUP: "my-db-resource-group"
      DISPG_DB_VNET_NAME: "my-db-vnet"
      DISPG_AKS_VNET_NAME: "my-aks-vnet"
      DISPG_AKS_RESOURCE_GROUP: "my-aks-resource-group"
      DISPG_WORKLOAD_IDENTITY_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
```

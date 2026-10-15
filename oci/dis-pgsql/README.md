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
| `DISPG_CLUSTER_ID` | - | Yes | Identifier of the cluster that runs the operator |

A cluster can read the variables from the dis-system Key Vault instead of inline values. The `secrets` layer syncs them into the `dis-pgsql-vars` Secret in `flux-system`. The Flux Kustomization for `.` reads that Secret with `postBuild.substituteFrom`.

| Key Vault secret | Variable |
|------------------|----------|
| `dis-pgsql-azure-subscription-id` | `DISPG_AZURE_SUBSCRIPTION_ID` |
| `dis-pgsql-azure-tenant-id` | `DISPG_AZURE_TENANT_ID` |
| `dis-pgsql-db-resource-group` | `DISPG_DB_RESOURCE_GROUP` |
| `dis-pgsql-db-vnet-name` | `DISPG_DB_VNET_NAME` |
| `dis-pgsql-aks-vnet-name` | `DISPG_AKS_VNET_NAME` |
| `dis-pgsql-aks-resource-group` | `DISPG_AKS_RESOURCE_GROUP` |
| `dis-pgsql-workload-identity-client-id` | `DISPG_WORKLOAD_IDENTITY_CLIENT_ID` |
| `dis-pgsql-cluster-id` | `DISPG_CLUSTER_ID` |

## Layers

| Path | Description |
|------|-------------|
| `.` | The operator OCIRepository and its Flux Kustomization, in `flux-system` |
| `apps` | Same resources as `.` |
| `multitenancy` | Same resources as `.`, moved to `platform-system` |
| `secrets` | `ExternalSecret` in `flux-system` that reads the input variables from `dis-system-store` (`oci/external-secrets-operator` `adminservices/post-deploy` or `apps/post-deploy`). The `.` layer depends on it for `substituteFrom`. Apply this layer first. Clusters with inline values do not use this layer. |

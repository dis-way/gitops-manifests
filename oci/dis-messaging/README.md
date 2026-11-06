# DIS Messaging Operator

Deploys the DIS Messaging Operator, which manages Azure Service Bus queues for DIS products (RFC 0018).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISMSG_AZURE_SUBSCRIPTION_ID` | - | Yes | Azure subscription ID of the Azure Service Bus namespace |
| `DISMSG_AZURE_TENANT_ID` | - | Yes | Azure tenant ID of that subscription |
| `DISMSG_NAMESPACE_RESOURCE_ID` | - | Yes | Resource ID of the Azure Service Bus namespace the operator creates queues in |
| `DISMSG_ENV` | - | Yes | DIS environment of the cluster, for example `at22` |

## Layers

| Path | Description |
|------|-------------|
| `.` | The operator OCIRepository and its Flux Kustomization, in `flux-system` |
| `multitenancy` | Same resources as `.`, moved to `platform-system` |

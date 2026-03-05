# OpenCost

OpenCost deployment for AKS clusters with Azure Managed Prometheus integration using a sidecar proxy for authentication.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AZURE_TENANT_ID` | - | Yes | Azure Tenant ID |
| `OPENCOST_CLIENT_ID` | - | Yes | Client ID of the User-Assigned Managed Identity for Workload Identity |
| `AZURE_PROMETHEUS_ENDPOINT` | - | Yes | Base Azure Monitor workspace URL (e.g. up to `/accounts/<name>`) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, HelmRepository, and HelmRelease with `aad-auth-proxy` sidecar |
| `apps` | Standard overlay that includes only base |
| `multitenancy` | Overlay with `platform-system` namespace patches for shared clusters |
| `policies` | Placeholder for future authorization or network policies |

## Deployment Notes

### The Pathing Trap
The `AZURE_PROMETHEUS_ENDPOINT` variable **must** be the base workspace-level path (ending at `/accounts/<workspace-name>`) and should **not** include the `/api/v1/query` suffix. OpenCost automatically appends the necessary API paths to the configured URL. Providing the full query path will result in double-pathing (e.g. `.../api/v1/query/api/v1/query`) and 404 errors.

### Authentication
Authentication to Azure Managed Prometheus is handled by the `aad-auth-proxy` sidecar container using **Azure Workload Identity**. Ensure the Managed Identity has the `Monitoring Data Reader` role on the Azure Monitor Workspace.

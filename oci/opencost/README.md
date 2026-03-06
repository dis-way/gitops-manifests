# OpenCost

OpenCost deployment for AKS clusters with Azure Managed Prometheus integration using a sidecar proxy for authentication.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AZURE_TENANT_ID` | - | Yes | Azure Tenant ID |
| `OPENCOST_CLIENT_ID` | - | Yes | Client ID of the User-Assigned Managed Identity for Workload Identity |
| `AZURE_PROMETHEUS_ENDPOINT` | - | Yes | Base Azure Monitor workspace URL (e.g. up to `/accounts/<name>`) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for policies) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for policies) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, HelmRepository, and HelmRelease with `aad-auth-proxy` sidecar |
| `apps` | Standard overlay that includes only base |
| `multitenancy` | Overlay with `platform-system` namespace patches and Linkerd policies |
| `policies` | Linkerd authorization policies for health probes and proxy admin |

## Usage

### Standard (`apps`)

Basic deployment in the `opencost-system` namespace.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./apps
  postBuild:
    substitute:
      AZURE_TENANT_ID: "..."
      OPENCOST_CLIENT_ID: "..."
      AZURE_PROMETHEUS_ENDPOINT: "https://..."
```

### Multitenancy (`multitenancy`)

Deployment in the `platform-system` namespace with Linkerd authorization policies.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./multitenancy
  postBuild:
    substitute:
      AZURE_TENANT_ID: "..."
      OPENCOST_CLIENT_ID: "..."
      AZURE_PROMETHEUS_ENDPOINT: "https://..."
      AKS_VNET_IPV4_CIDR: "10.0.0.0/16"
      AKS_VNET_IPV6_CIDR: "fd00::/48"
```

## Deployment Notes

### The Pathing Trap
The `AZURE_PROMETHEUS_ENDPOINT` variable **must** be the base workspace-level path (ending at `/accounts/<workspace-name>`) and should **not** include the `/api/v1/query` suffix. OpenCost automatically appends the necessary API paths to the configured URL. Providing the full query path will result in double-pathing (e.g. `.../api/v1/query/api/v1/query`) and 404 errors.

### Authentication
Authentication to Azure Managed Prometheus is handled by the `aad-auth-proxy` sidecar container using **Azure Workload Identity**. Ensure the Managed Identity has the `Monitoring Data Reader` role on the Azure Monitor Workspace.

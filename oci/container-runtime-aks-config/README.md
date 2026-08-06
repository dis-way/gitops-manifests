# Container Runtime AKS Config

Shared AKS cluster configuration including monitoring, metrics, storage, RBAC, and secret management.

## Components

| Component | Path | Description |
|-----------|------|-------------|
| Access Token Credentials | `base/accesstokencredentials` | ExternalSecret pulling PFX certificate from Azure Key Vault |
| AMA Metrics Prometheus Config | `base/ama-metrics-prometheus-config` | Prometheus scrape config for centralized monitoring (Traefik metrics) |
| AMA Metrics Settings | `base/ama-metrics-settings-configmap` | Azure Monitor Agent metrics collection settings |
| Container AZM MS Agent Config | `base/container-azm-ms-agentconfig` | Container Insights log collection settings |
| Datakeys Storage Class | `base/datakeys-storage-class` | Azure Files StorageClass and PVC for data protection keys |
| Metrics Server Config | `base/metrics-server-config` | Metrics server nanny configuration |
| RBAC | `base/rbac-authorization-k8s` | ClusterRole and binding for read access and pod restart |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ALTINN_KV_URI` | - | Yes | Azure Key Vault URL (e.g. `https://<name>.vault.azure.net/`) |
| `ALTINN_KV_SERVICE_ACCOUNT_NAME` | - | Yes | Kubernetes service account with federated identity for Key Vault access |
| `AKS_READ_EVERYTHING_AND_RESTART_GROUP_ID` | - | Yes | Entra ID group object ID for RBAC binding |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./apps
  postBuild:
    substitute:
      ALTINN_KV_URI: "https://my-keyvault.vault.azure.net/"
      ALTINN_KV_SERVICE_ACCOUNT_NAME: "my-service-account"
```

RBAC is deployed separately:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./base/rbac-authorization-k8s
  postBuild:
    substitute:
      AKS_READ_EVERYTHING_AND_RESTART_GROUP_ID: "00000000-0000-0000-0000-000000000000"
```

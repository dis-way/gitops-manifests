# cert-manager

Deploys cert-manager via the Jetstack Helm chart with Azure Workload Identity support and CRD management.

## Resources

- `cert-manager` Namespace
- `jetstack` HelmRepository (charts.jetstack.io)
- `cert-manager` HelmRelease (chart version 1.19.3)

## Variables

No variables. All values are hardcoded in the HelmRelease.

## Paths

| Path | Description |
|------|-------------|
| `./base` | Core resources (Namespace, HelmRepository, HelmRelease) |
| `./apps` | Alias for `./base` |
| `./multitenancy` | Moves HelmRepository and HelmRelease to `platform-system` namespace, sets `targetNamespace: cert-manager` and `releaseName: cert-manager` |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./base
```

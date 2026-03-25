# cert-manager

Deploys cert-manager via the Jetstack Helm chart with Azure Workload Identity support and CRD management.

## Variables

No variables. All values are hardcoded in the HelmRelease.

## Layers

| Path | Description |
|------|-------------|
| `base` | Core resources (Namespace, HelmRepository, HelmRelease) |
| `apps` | Alias for `base` |
| `platform-aks` | AKS platform overlay; currently identical to `base` |
| `multitenancy` | Moves HelmRepository and HelmRelease to `platform-system` namespace, sets `targetNamespace: cert-manager` and `releaseName: cert-manager` |

# kube-state-metrics

Deploys kube-state-metrics configured to expose Flux CD resource status as custom metrics.

## Variables

No variables.

## Layers

| Path | Description |
|------|-------------|
| `base` | Deploys kube-state-metrics into the `kube-state-metrics` namespace with custom resource state metrics for all Flux resource types |
| `multitenancy` | Relocates the HelmRepository and HelmRelease into `platform-system` for multitenant clusters where `flux-applier` runs in that namespace |

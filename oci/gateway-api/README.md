# Gateway API

Deploys the upstream Kubernetes Gateway API standard-channel CRDs from `kubernetes-sigs/gateway-api` via Flux `GitRepository` + `Kustomization`.

The `GitRepository` is named `gateway-api-upstream`, not `gateway-api`. On AKS the flux configuration that deploys this package is named `gateway-api`, and whenever that configuration is updated the Azure `fluxconfig-controller` deletes any `GitRepository` in its namespace with the configuration's name.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | Flux `GitRepository` and `Kustomization` applying `./config/crd/standard` from `flux-system` |
| `multitenancy` | Overlay that moves the Flux `GitRepository` and `Kustomization` to `platform-system` |

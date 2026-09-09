# Gateway API

Deploys the upstream Kubernetes Gateway API standard-channel CRDs from `kubernetes-sigs/gateway-api` via Flux `GitRepository` + `Kustomization`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | Flux `GitRepository` and `Kustomization` applying `./config/crd/standard` from `flux-system` |
| `multitenancy` | Overlay that moves the Flux `GitRepository` and `Kustomization` to `platform-system` |

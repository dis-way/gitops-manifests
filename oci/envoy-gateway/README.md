# Envoy Gateway

Deploys Envoy Gateway, a Kubernetes Gateway API implementation, via a Flux HelmRelease.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace (`envoy-gateway-system`), OCI HelmRepository, and HelmRelease installing the `gateway-helm` chart; all images (control plane, certgen, shutdown manager, rate limit, and the Envoy data plane) mirrored through `altinncr.azurecr.io` via `global.imageRegistry` |
| `multitenancy` | Moves HelmRepository/HelmRelease to `platform-system`, deploys chart resources into `envoy-gateway-system` |

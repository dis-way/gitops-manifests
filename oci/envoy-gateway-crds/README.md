# Envoy Gateway CRDs

Deploys the Envoy Gateway `gateway.envoyproxy.io` CustomResourceDefinitions via a Flux HelmRelease. Gateway API CRDs are intentionally disabled here — they are owned by the `gateway-api` package.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | OCI HelmRepository, and HelmRelease installing the `gateway-crds-helm` chart. Expects the `envoy-gateway-system` namespace to exist — it is created by the `envoy-gateway` package |
| `multitenancy` | Moves HelmRepository/HelmRelease to `platform-system` |

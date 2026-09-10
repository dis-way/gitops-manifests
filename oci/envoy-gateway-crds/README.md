# Envoy Gateway CRDs

Deploys the Envoy Gateway `gateway.envoyproxy.io` CustomResourceDefinitions, vendored from the upstream release asset. Gateway API CRDs are not included here — they are owned by the `gateway-api` package.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | The 8 `gateway.envoyproxy.io` CRDs, applied directly by Flux. No HelmRelease and no namespace needed — CRDs are cluster-scoped |
| `multitenancy` | Passthrough overlay, kept so consumers referencing this path keep working |

## Upgrading

`base/envoy-gateway-crds.yaml` is generated — do not edit it by hand. The version is pinned in `scripts/update-crds.sh` and maintained by Renovate, which groups it with the chart version in the `envoy-gateway` package so the CRDs and the control plane always move together. `.github/workflows/refresh-envoy-gateway-crds.yml` re-downloads the matching asset on the Renovate PR; to refresh manually, run:

```
./oci/envoy-gateway-crds/scripts/update-crds.sh
```

Helm is deliberately not used: the `gateway-crds-helm` chart embeds ~5 MB of CRD templates in the Helm release object, which exceeds the 1 MB Kubernetes Secret limit regardless of which CRDs are enabled via values.

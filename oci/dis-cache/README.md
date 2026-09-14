# DIS Cache Operator

Deploys dis-cache-operator. It turns a team's `Cache` resource into a Valkey instance run by the valkey-operator, with a password Secret, a NetworkPolicy, and linkerd policies (RFC 0014 in Altinn/altinn-platform).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DISCACHE_VALKEY_IMAGE` | - | Yes | Valkey image for every cache, on the ACR pull-through path. An empty string keeps the upstream default image. |
| `DISCACHE_EXPORTER_IMAGE` | - | Yes | Metrics exporter image for every cache, on the ACR pull-through path. An empty string keeps the upstream default image. |

## Layers

| Path | Description |
|------|-------------|
| `base` | OCIRepository and Flux Kustomization for the operator artifact, in `flux-system`, deploying into `dis-cache-operator-system` |
| `apps` | Minimal overlay referencing base |
| `multitenancy` | Moves the Flux objects to `platform-system` and waits for the valkey-operator package, because the operator needs the `ValkeyCluster` CRD at start |

# DIS Cache Operator

Deploys dis-cache-operator. It turns a team's `Cache` resource into a Valkey instance run by the valkey-operator, with a password Secret, a NetworkPolicy, and linkerd policies (RFC 0014 in Altinn/altinn-platform).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Images

The Flux Kustomization patches two environment variables into the operator Deployment. They name the images the operator sets on every cache, on the ACR pull-through path. Renovate updates the tags.

| Variable | Image |
|----------|-------|
| `DISCACHE_VALKEY_IMAGE` | `altinncr.azurecr.io/docker.io/valkey/valkey` |
| `DISCACHE_EXPORTER_IMAGE` | `altinncr.azurecr.io/docker.io/oliver006/redis_exporter` |

## Layers

| Path | Description |
|------|-------------|
| `base` | OCIRepository and Flux Kustomization for the operator artifact, in `flux-system`, deploying into `dis-cache-operator-system` |
| `apps` | Minimal overlay referencing base |
| `multitenancy` | Moves the Flux objects to `platform-system` and waits for the valkey-operator package, because the operator needs the `ValkeyCluster` CRD at start |

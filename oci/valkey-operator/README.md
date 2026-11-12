# valkey-operator

Deploys the official Valkey operator (valkey-io/valkey-operator) — it runs Valkey instances declared as `ValkeyCluster` resources. On DIS clusters, `dis-cache-operator` creates those resources for teams (RFC 0014 in Altinn/altinn-platform).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | Core resources: Namespace, HelmRepository, HelmRelease |
| `apps` | Minimal overlay referencing base |
| `multitenancy` | Moves HelmRepository/HelmRelease to `platform-system`, deploys chart into `valkey-operator-system` |

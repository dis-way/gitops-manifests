# kro

Deploys kro (Kube Resource Orchestrator) — a Kubernetes-native tool for creating and managing complex custom resources via ResourceGraphDefinitions (RGDs).

## Variables

No configurable variables. kro has no postBuild substitutions.

## Layers

| Path | Description |
|------|-------------|
| `base` | Core resources: Namespace, HelmRepository, HelmRelease |
| `apps` | Minimal overlay referencing base |
| `multitenancy` | Moves HelmRepository/HelmRelease to `platform-system`, deploys chart into `kro-system` |

## Examples

The `examples/` directory contains sample ResourceGraphDefinitions:

- `simple-webapp.yaml` — Creates a Deployment + Service from a single custom resource
- `namespace-with-quota.yaml` — Creates a namespace with ResourceQuota and NetworkPolicy for tenant isolation

# External Secrets Operator

Deploys the External Secrets Operator for syncing secrets from external providers (e.g., Azure Key Vault) into Kubernetes.

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Additional application resources |
| `multitenancy` | Multi-tenant configuration |

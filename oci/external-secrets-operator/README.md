# External Secrets Operator

Deploys the External Secrets Operator for syncing secrets from external providers (e.g., Azure Key Vault) into Kubernetes.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ALTINN_KV_ESO_CLIENT_ID` | — | apps post-deploy | Client ID of the user-assigned identity ESO uses against the Altinn Key Vault |
| `ALTINN_KV_URL` | — | apps post-deploy | Vault URI of the Altinn Key Vault, e.g. `https://<name>.vault.azure.net/` |
| `SO_KV_ESO_CLIENT_ID` | — | apps post-deploy | Client ID of the user-assigned identity ESO uses against the serviceowner Key Vault |
| `SO_KV_URL` | — | apps post-deploy | Vault URI of the serviceowner Key Vault |
| `TENANT_ID` | — | apps post-deploy | Azure tenant ID for both workload identities |

`base`, `apps`, and `multitenancy` use no variables — substitution only applies to `apps/post-deploy`.

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Standard variant; `base` unchanged |
| `apps/post-deploy` | Workload identity ServiceAccount + `ClusterSecretStore` pair per Key Vault, applied after the operator has reconciled |
| `multitenancy` | Runs the HelmRelease from `platform-system` targeting the `external-secrets` namespace |

## Key Vault access

The operator runs with `serviceAccount.create: false` and no Azure identity of its own. Each `ClusterSecretStore`
points at its own ServiceAccount through `serviceAccountRef`, and ESO exchanges that ServiceAccount's token for an
Azure token using the `azure.workload.identity/client-id` and `azure.workload.identity/tenant-id` annotations.

| Key Vault | ServiceAccount | ClusterSecretStore |
|-----------|----------------|--------------------|
| Altinn | `altinn-kv-eso` | `altinn-keyvault-store` |
| Serviceowner | `so-kv-eso` | `serviceowner-keyvault-store` |

These live in `post-deploy` because both the `external-secrets` namespace and the `ClusterSecretStore` CRD are created
by `apps` — applying them in the same Kustomization would fail until the chart has installed its CRDs.

Both ServiceAccounts are in the `external-secrets` namespace, so each identity needs a federated credential on the
cluster's OIDC issuer with subject `system:serviceaccount:external-secrets:<serviceaccount-name>`, plus a Key Vault
role assignment on the vault it reads. Without the federated credential the stores report `NotReady` and every
`ExternalSecret` using them fails to sync.

Consumers reference a store by name, and because these are cluster-scoped they work from any namespace:

```yaml
secretStoreRef:
  kind: ClusterSecretStore
  name: altinn-keyvault-store
```

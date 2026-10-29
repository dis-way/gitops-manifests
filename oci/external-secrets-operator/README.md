# External Secrets Operator

Deploys the External Secrets Operator for syncing secrets from external providers (e.g., Azure Key Vault) into Kubernetes.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ALTINN_KV_ESO_CLIENT_ID` | — | apps + platform-aks post-deploy | Client ID of the user-assigned identity ESO uses against the Altinn Key Vault |
| `ALTINN_KV_URL` | — | apps + platform-aks post-deploy | Vault URI of the Altinn Key Vault, e.g. `https://<name>.vault.azure.net/` |
| `DIS_SYSTEM_KV_ESO_CLIENT_ID` | — | adminservices + multitenancy post-deploy | Client ID of the dis-system Key Vault reader identity (`dis_system_kv_reader_client_id` output of the `dis_system_kv` module) |
| `DIS_SYSTEM_KV_URL` | — | adminservices + multitenancy post-deploy | Vault URI of the dis-system Key Vault (`dis_system_kv_uri` output of the `dis_system_kv` module) |
| `SO_KV_ESO_CLIENT_ID` | — | apps post-deploy | Client ID of the user-assigned identity ESO uses against the serviceowner Key Vault |
| `SO_KV_URL` | — | apps post-deploy | Vault URI of the serviceowner Key Vault |
| `TENANT_ID` | — | apps, platform-aks, adminservices + multitenancy post-deploy | Azure tenant ID for the workload identities |

`base`, `apps`, `platform-aks`, `adminservices`, and `multitenancy` use no variables — substitution only applies to the
`post-deploy` layers.

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Standard variant; `base` unchanged |
| `apps/post-deploy` | Workload identity ServiceAccount + `ClusterSecretStore` for the Altinn and serviceowner Key Vaults, plus the namespaced `dis-system-store` `SecretStore` in `flux-system` over the Altinn Key Vault, applied after the operator has reconciled |
| `platform-aks` | Platform cluster variant; `base` unchanged |
| `platform-aks/post-deploy` | Altinn Key Vault `ClusterSecretStore` only — platform clusters have no serviceowner vault and no `dis-system-store` |
| `adminservices` | Admin cluster variant; `base` unchanged |
| `adminservices/post-deploy` | Workload identity ServiceAccount + namespaced `SecretStore` in `platform-system` for the dis-system Key Vault |
| `multitenancy` | Runs the HelmRelease from `platform-system` targeting the `external-secrets` namespace |
| `multitenancy/post-deploy` | Workload identity ServiceAccount + namespaced `dis-system-store` `SecretStore` in `platform-system` for the dis-system Key Vault |

## Key Vault access

The operator runs with `serviceAccount.create: false` and no Azure identity of its own. Each `ClusterSecretStore`
points at its own ServiceAccount through `serviceAccountRef`, and ESO exchanges that ServiceAccount's token for an
Azure token using the `azure.workload.identity/client-id` and `azure.workload.identity/tenant-id` annotations.

| Key Vault | ServiceAccount | ClusterSecretStore | Layer |
|-----------|----------------|--------------------|-------|
| Altinn | `altinn-kv-eso` | `altinn-keyvault-store` | `apps`, `platform-aks` |
| Serviceowner | `so-kv-eso` | `serviceowner-keyvault-store` | `apps` |
| dis-system | `flux-system/dis-secret-sync-sa` | `dis-system-store` (namespaced `SecretStore` in `flux-system`) | `adminservices` |
| dis-system | `platform-system/dis-secret-sync-sa` | `dis-system-store` (namespaced `SecretStore` in `platform-system`) | `multitenancy` |
| Altinn | `flux-system/dis-secret-sync-sa` | `dis-system-store` (namespaced `SecretStore` in `flux-system`) | `apps` |

These live in `post-deploy` because both the `external-secrets` namespace and the `ClusterSecretStore` CRD are created
by the operator layer — applying them in the same Kustomization would fail until the chart has installed its CRDs.

`dis-system-store` and its `dis-secret-sync-sa` ServiceAccount carry `kustomize.toolkit.fluxcd.io/prune: disabled`.
Packages read their input variables through them, so Flux must never delete them, even when a Kustomization is
renamed, its path changes, or `prune` is turned on. Removing one from the manifests leaves it orphaned in the
cluster, so deleting one means doing it by hand. The `ClusterSecretStore`s (`altinn-keyvault-store`,
`serviceowner-keyvault-store`) and their ServiceAccounts are to be replaced by `dis-system-store`, so they stay
prunable and go away with the manifests.

Every ServiceAccount except the dis-system one is in the `external-secrets` namespace, so each identity needs a federated credential on the
cluster's OIDC issuer with subject `system:serviceaccount:external-secrets:<serviceaccount-name>`, plus read access
to the vault it reads — a `Key Vault Secrets User` role assignment on RBAC vaults, or a get/list access policy on
vaults still using the access-policy model. Without the federated credential the stores report `NotReady` and every
`ExternalSecret` using them fails to sync. The dis-system ServiceAccount and its `SecretStore` are in
`flux-system` instead: admin clusters run every Flux Kustomization there, and `postBuild.substituteFrom` only reads
Secrets from the Kustomization's own namespace. Its federated credential subject is therefore
`system:serviceaccount:flux-system:dis-secret-sync-sa` (`dis_system_kv_namespace = "flux-system"` on the
`dis_system_kv` module), and only `ExternalSecret`s in `flux-system` can use the store. DIS core (multitenancy)
clusters run their Flux Kustomizations in `platform-system`, so there the ServiceAccount and store are in
`platform-system` and the federated credential subject is
`system:serviceaccount:platform-system:dis-secret-sync-sa`. A package's `secrets` layer must then create its
`ExternalSecret` in `platform-system`; the existing layers hardcode `flux-system` and need a multitenancy overlay.

`dis-system-store` is the store name every package's `secrets` layer references, so the same manifests work on every
cluster. On apps clusters it reads the existing Altinn Key Vault rather than a separate dis-system vault: the
`flux-system/dis-secret-sync-sa` ServiceAccount carries the `ALTINN_KV_ESO_CLIENT_ID` identity, which needs a second
federated credential with subject `system:serviceaccount:flux-system:dis-secret-sync-sa`.

Consumers reference a store by name, and because these are cluster-scoped they work from any namespace:

```yaml
secretStoreRef:
  kind: ClusterSecretStore
  name: altinn-keyvault-store
```

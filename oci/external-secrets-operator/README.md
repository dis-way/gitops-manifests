# External Secrets Operator

Deploys the External Secrets Operator for syncing secrets from external providers (e.g., Azure Key Vault) into Kubernetes.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ALTINN_KV_ESO_CLIENT_ID` | — | apps + platform-aks post-deploy | Client ID of the user-assigned identity ESO uses against the Altinn Key Vault |
| `ALTINN_KV_URL` | — | apps + platform-aks post-deploy | Vault URI of the Altinn Key Vault, e.g. `https://<name>.vault.azure.net/` |
| `CENTRAL_ACCESSTOKEN_KV_URL` | — | multitenancy central-accesstoken | Vault URI of the Key Vault holding the central access token. Read from the `multitenancy/secrets` layer |
| `DIS_SYSTEM_KV_ESO_CLIENT_ID` | — | adminservices + multitenancy post-deploy | Client ID of the dis-system Key Vault reader identity (`dis_system_kv_reader_client_id` output of the `dis_system_kv` module) |
| `DIS_SYSTEM_KV_URL` | — | adminservices + multitenancy post-deploy | Vault URI of the dis-system Key Vault (`dis_system_kv_uri` output of the `dis_system_kv` module) |
| `SO_KV_ESO_CLIENT_ID` | — | apps post-deploy | Client ID of the user-assigned identity ESO uses against the serviceowner Key Vault |
| `SO_KV_URL` | — | apps post-deploy | Vault URI of the serviceowner Key Vault |
| `TENANT_ID` | — | apps, platform-aks, adminservices + multitenancy post-deploy | Azure tenant ID for the workload identities |

`base`, `apps`, `platform-aks`, `adminservices`, and `multitenancy` use no variables — substitution only applies to the
`post-deploy` layers.

`multitenancy/central-accesstoken` reads its variables from the `multitenancy/secrets` layer, through
`postBuild.substituteFrom` on the `external-secrets-operator-vars` Secret. The ExternalSecret and the Secret are in
`platform-system`, next to `dis-system-store` and the Flux Kustomizations on DIS core clusters. Every Key Vault secret
below must exist in the vault behind `dis-system-store`, or the ExternalSecret fails to sync.

| Key Vault secret | Variable |
|------------------|----------|
| `external-secrets-operator-central-accesstoken-kv-url` | `CENTRAL_ACCESSTOKEN_KV_URL` |

The other `post-deploy` layers keep `postBuild.substitute`: `apps` and `adminservices` create `dis-system-store`
themselves, so they cannot read their own variables through it.

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Standard variant; `base` unchanged |
| `apps/post-deploy` | Workload identity ServiceAccount + `ClusterSecretStore` for the Altinn and serviceowner Key Vaults, plus the namespaced `dis-system-store` `SecretStore` in `flux-system` over the Altinn Key Vault, applied after the operator has reconciled |
| `platform-aks` | Platform cluster variant; `base` unchanged |
| `platform-aks/post-deploy` | Altinn Key Vault `ClusterSecretStore` only — platform clusters have no serviceowner vault and no `dis-system-store` |
| `adminservices` | Admin cluster variant; `base` unchanged |
| `adminservices/post-deploy` | Workload identity ServiceAccount + namespaced `SecretStore` in `flux-system` for the dis-system Key Vault |
| `multitenancy` | Runs the HelmRelease from `platform-system` targeting the `external-secrets` namespace |
| `multitenancy/post-deploy` | Workload identity ServiceAccount + namespaced `dis-system-store` `SecretStore` in `platform-system` for the dis-system Key Vault |
| `multitenancy/central-accesstoken` | `ApplicationIdentity` + `central-accesstoken-store` `ClusterSecretStore` for the central access token, limited to namespaces labeled `accesstoken.dis.altinn.cloud/enabled: "true"`. Depends on `multitenancy/secrets` |
| `multitenancy/secrets` | `ExternalSecret` in `platform-system` that writes the `external-secrets-operator-vars` Secret for `multitenancy/central-accesstoken` from `dis-system-store`. Depends on `multitenancy/post-deploy` |

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
| Central access token | `platform-system/central-accesstoken-eso` | `central-accesstoken-store` | `multitenancy` |

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

### Central access token

Some products sign their requests with a central access token. `central-accesstoken-store` serves it only to
namespaces with the label `accesstoken.dis.altinn.cloud/enabled: "true"`. Namespaces without the label cannot use the
store, so products that do not need the token get no Secret. A team asks the platform team for access, the platform
team adds the label to the product namespace, and the team then deploys an `ExternalSecret` that references the store.

The store does not create its own ServiceAccount. `multitenancy/central-accesstoken` creates the
`platform-system/central-accesstoken-eso` `ApplicationIdentity`, and dis-identity-operator creates the managed identity,
its federated credential, and a ServiceAccount with the same name that carries the client and tenant IDs. No identity
ID passes through Flux. On the first deploy the store reports `NotReady`: the managed identity exists only after the
operator has reconciled, and it then needs read access to the vault. Grant it that access outside the cluster, and the
store becomes ready on its next refresh.

The vault is shared, and the namespace label is the only limit in the cluster: a labeled namespace can read every
secret the identity can read. Grant the identity `Key Vault Secrets User` on the access token secret alone, not on the
vault. Vaults that still use access policies cannot limit access to one secret.

On DIS core clusters the Flux Kustomizations depend on each other in this order: `multitenancy` →
`multitenancy/post-deploy` (`dis-system-store`) → `multitenancy/secrets` → `multitenancy/central-accesstoken`, which
also depends on the dis-identity Kustomization for the `ApplicationIdentity` CRD.

The `ApplicationIdentity` and `central-accesstoken-store` carry `kustomize.toolkit.fluxcd.io/prune: disabled`. Product
`ExternalSecret`s depend on the store. A recreated identity is a new principal and has no vault access.

Consumers reference a store by name, and because these are cluster-scoped they work from any namespace:

```yaml
secretStoreRef:
  kind: ClusterSecretStore
  name: altinn-keyvault-store
```

# Flux Dispatch

Deploys the Flux Dispatch service, which receives Flux reconciliation webhooks and
triggers GitHub Actions workflows in product repositories via `repository_dispatch`.

## Resources

- `dis-platform` Namespace
- `flux-dispatch-config` OCIRepository (oci://altinncr.azurecr.io/dis/kustomize/flux-dispatch)
- `flux-dispatch-config` Kustomization (Flux)

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DRY_RUN` | `false` | No | Set `true` for the initial rollout so the service logs the dispatches it would send without calling GitHub; set `false` once the GitHub App is provisioned |
| `FLUX_DISPATCH_WORKLOAD_IDENTITY_CLIENT_ID` | - | Yes | Client ID of the Azure Workload Identity used by Flux Dispatch |
| `GITHUB_APP_ID` | - | Yes | App ID of the `flux-dispatch` GitHub App registration |
| `GITHUB_INSTALLATION_ID` | - | Yes | Installation ID of the `flux-dispatch` GitHub App registration |
| `KV_URI` | - | Yes | URI of the Azure Key Vault holding the service's secrets |
| `KV_SECRET_NAME_GITHUB_APP_KEY` | - | Yes | Name of the Key Vault secret holding the GitHub App's private key |

`GITHUB_APP_ID` and `GITHUB_INSTALLATION_ID` come from the GitHub App registration (App ID and
installation ID respectively), not from Azure.

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./
  postBuild:
    substitute:
      DRY_RUN: "true"   # initial rollout: log intended dispatches, don't call GitHub
      FLUX_DISPATCH_WORKLOAD_IDENTITY_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
      GITHUB_APP_ID: "000000"
      GITHUB_INSTALLATION_ID: "00000000"
      KV_URI: "https://example-kv.vault.azure.net/"
      KV_SECRET_NAME_GITHUB_APP_KEY: "flux-dispatch-github-app-key"
```

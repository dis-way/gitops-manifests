# Flux Dispatch

Deploys the Flux Dispatch service, which receives Flux reconciliation webhooks and
triggers GitHub Actions workflows in product repositories via `repository_dispatch`.

## Resources

- `dis-platform` Namespace
- `flux-dispatch-config` OCIRepository (oci://altinncr.azurecr.io/dis/kustomize/flux-dispatch)
- `flux-dispatch-config` Kustomization (Flux)

## Variables

No variables.

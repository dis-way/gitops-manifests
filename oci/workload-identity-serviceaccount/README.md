# Workload Identity ServiceAccount

A single templated ServiceAccount annotated for Azure Workload Identity, for clusters that
need a federated identity beyond the ones the shared terraform modules already ship.

One rendering produces one ServiceAccount - `envsubst` cannot loop - so a cluster that
needs several adds one kustomization entry per identity, each with its own substitutes.
`WI_SA_NAME` and the `system:serviceaccount:<namespace>:<name>` subject on the federated
identity credential must match, or the pod fails at token exchange (AADSTS700213) rather
than at apply.

The tenant id is not templated; the webhook falls back to the cluster's default tenant.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `WI_SA_NAME` | - | Yes | ServiceAccount name; must match the federated identity credential subject |
| `WI_SA_NAMESPACE` | `default` | No | Namespace of the ServiceAccount; must already exist |
| `WI_CLIENT_ID` | - | Yes | Client id of the user-assigned identity or app registration |

## Layers

| Path | Description |
|------|-------------|
| `base` | The templated ServiceAccount |

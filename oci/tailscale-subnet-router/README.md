# Tailscale Subnet Router

Deploys a Tailscale subnet router pod that connects to a Headscale coordination server and optionally advertises subnets to the Tailnet.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `TS_ADVERTISE_ROUTES` | `""` | No | Subnet CIDR(s) to advertise, e.g. `10.0.0.0/16`. Empty string clears all advertised routes. |
| `AKS_NAME` | — | Yes | AKS cluster name (from Terraform output `aks_name`), used as the Headscale node name. |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./base
  postBuild:
    substitute:
      AKS_NAME: "my-aks-cluster"
      TS_ADVERTISE_ROUTES: "10.0.0.0/16"
```

The `tailscale-authkey` secret must be patched with a valid Headscale pre-auth key before or alongside deployment:

```sh
headscale preauthkeys create --reusable --tags tag:<aks_name>
```

# AKS Tailscale Subnet Router

Deploys a Tailscale subnet router pod that connects to a Headscale coordination server and optionally advertises subnets to the Tailnet.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_NAME` | — | Yes | AKS cluster name (from Terraform output `aks_name`), used as the Headscale node name. |
| `TS_ADVERTISE_ROUTES` | — | Yes | Subnet CIDR(s) to advertise, comma-separated, e.g. `10.0.0.0/16`. |
| `HEADSCALE_PREAUTH_KEY` | — | Yes | Headscale pre-auth key from the deploy pipeline. Generate with: `headscale preauthkeys create --reusable --tags tag:<aks_name>` |

A cluster can read all three variables from the dis-system Key Vault instead of inline values. The `secrets` layer syncs them into the `tailscale-subnet-router-vars` Secret in `flux-system`. The Flux Kustomization for `.` reads that Secret with `postBuild.substituteFrom`. Every Key Vault secret must exist, or the `ExternalSecret` fails to sync.

| Key Vault secret | Variable |
|------------------|----------|
| `tailscale-subnet-router-aks-name` | `AKS_NAME` |
| `tailscale-subnet-router-ts-advertise-routes` | `TS_ADVERTISE_ROUTES` |
| `tailscale-subnet-router-headscale-preauth-key` | `HEADSCALE_PREAUTH_KEY` |

## Layers

| Path | Description |
|------|-------------|
| `.` | Includes `base` |
| `base` | Namespace, RBAC, subnet router Deployment and NetworkPolicies. All ingress is denied. Egress is allowed to DNS, the API server (CiliumNetworkPolicy, so the package requires Cilium), private ranges on any port for the advertised routes, public HTTPS and UDP for headscale, DERP, STUN and WireGuard peers, and the in-cluster Traefik pods on 8443 for clusters that host headscale or a DERP relay behind their own Traefik |
| `secrets` | `ExternalSecret` in `flux-system` that reads the input variables from `dis-system-store` (`oci/external-secrets-operator` `adminservices/post-deploy` or `apps/post-deploy`). The `.` layer depends on it for `substituteFrom`. Apply this layer first. Clusters with inline values do not use this layer |

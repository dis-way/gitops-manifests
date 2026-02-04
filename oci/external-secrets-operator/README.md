# External Secrets Operator

Deploys the External Secrets Operator for syncing secrets from external providers (e.g., Azure Key Vault) into Kubernetes.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR (for policies) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR (for policies) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for policies) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for policies) |

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Additional application resources |
| `multitenancy` | Multi-tenant configuration |
| `policies` | Linkerd authorization policies for default-deny inbound |

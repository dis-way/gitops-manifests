# Azure Service Operator

Deploys Azure Service Operator v2 for managing Azure resources via Kubernetes CRDs.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `CRD_PATTERN` | - | Yes | Pattern for which Azure CRDs to install |
| `AZURE_TENANT_ID` | - | Yes | Azure AD tenant ID |
| `AZURE_CLIENT_ID` | - | Yes | Azure AD client ID for workload identity |
| `AZURE_SUBSCRIPTION_ID` | - | Yes | Azure subscription ID |
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

## Dependencies

- `cert-manager` must be installed (HelmRelease depends on it)

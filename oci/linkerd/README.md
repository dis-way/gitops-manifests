# Linkerd

Deploys Linkerd service mesh with High Availability configuration.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_INBOUND_POLICY` | `all-unauthenticated` | No | Default inbound policy for proxied workloads |
| `DISABLE_IPV6` | `false` | No | Disable IPv6 support in the proxy |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR (for policies) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR (for policies) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for policies) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for policies) |

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease with HA values, HelmRepository, cert-manager resources, and namespace |
| `apps` | Standalone overlay that includes only base |
| `post-deploy` | Rollout restart job for re-injecting proxies after upgrades |
| `multitenancy` | Multi-tenant overlay with platform-system namespace patches |
| `policies` | Linkerd authorization policies for control plane (webhooks, health checks, gRPC) |

## Deployment Notes

The `policies` layer contains AuthorizationPolicy CRDs that require the Linkerd CRDs to be installed first. Deploy policies via a separate Flux Kustomization that depends on the linkerd-crds HelmRelease.

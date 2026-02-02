# Linkerd

Linkerd service mesh with High Availability configuration.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_INBOUND_POLICY` | `all-unauthenticated` | No | Default inbound policy for proxied workloads |
| `DISABLE_IPV6` | `false` | No | Disable IPv6 support in the proxy |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR (policies only) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR (policies only) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (policies only) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (policies only) |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./base
  postBuild:
    substitute:
      DEFAULT_INBOUND_POLICY: "cluster-authenticated"
      DISABLE_IPV6: "true"
      AKS_VNET_IPV4_CIDR: "10.205.0.0/16"
      AKS_VNET_IPV6_CIDR: "fd12:2291:d70a::/56"
```

# Linkerd

Linkerd service mesh with High Availability configuration.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_INBOUND_POLICY` | `all-unauthenticated` | No | Default inbound policy for proxied workloads |
| `DISABLE_IPV6` | `false` | No | Disable IPv6 support in the proxy |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS pod IPv4 CIDR for kube-apiserver network authentication (policies only) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS pod IPv6 CIDR for kube-apiserver network authentication (policies only) |

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
```

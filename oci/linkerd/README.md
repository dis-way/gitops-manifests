# Linkerd

Linkerd service mesh with High Availability configuration.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_INBOUND_POLICY` | `all-unauthenticated` | No | Default inbound policy for proxied workloads |
| `DISABLE_IPV6` | `false` | No | Disable IPv6 support in the proxy |

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

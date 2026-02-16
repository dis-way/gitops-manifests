# Whoami

Deploys the [traefik/whoami](https://github.com/traefik/whoami) test service with Linkerd authorization policies.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS overlay pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS overlay pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNet IPv4 CIDR for kubelet NetworkAuthentication |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNet IPv6 CIDR for kubelet NetworkAuthentication |

## Usage

### Standard (`apps`)

Basic deployment with Traefik IngressRoute routing. No variables required.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./apps
```

### Multitenancy (`multitenancy`)

Deployment with Gateway API HTTPRoute and Linkerd authorization policies. Replaces the Traefik IngressRoute with a Kubernetes Gateway API HTTPRoute targeting the `traefik-gateway`.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./multitenancy
  postBuild:
    substitute:
      AKS_VNET_IPV4_CIDR: "10.0.0.0/16"
      AKS_VNET_IPV6_CIDR: "fd00::/48"
```

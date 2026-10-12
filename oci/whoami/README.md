# Whoami

Deploys the [traefik/whoami](https://github.com/traefik/whoami) test service with Linkerd authorization policies.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS overlay pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS overlay pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNet IPv4 CIDR for kubelet NetworkAuthentication (`multitenancy` only) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNet IPv6 CIDR for kubelet NetworkAuthentication (`multitenancy` only) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, Deployment, Service, HPA (2-20 replicas) and a Gateway API HTTPRoute on `/whoami` to `traefik/traefik-gateway`. Requests are 5m CPU / 16Mi for whoami and for the Linkerd proxy (proxy limits stay at the cluster defaults). Needs Gateway listeners that accept routes from the `whoami` namespace |
| `apps` | `base` plus a PodDisruptionBudget (`maxUnavailable: 1`) and a spread of replicas across nodes, so node drains never take every replica; used as an availability probe target |
| `multitenancy` | `base` and `policies` |
| `policies` | Linkerd authorization policies for mesh traffic and kubelet health checks |

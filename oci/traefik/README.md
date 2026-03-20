# Traefik

Deploys Traefik as the ingress controller for the Altinn platform via Flux HelmRelease (chart v39+).

CRDs (Traefik and Gateway API standard channel) are managed directly by the HelmRelease via `install/upgrade.crds: CreateReplace`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_NODE_RG` | — | Yes | Azure Resource Group for AKS nodes (Load Balancer annotation) |
| `PUBLIC_IP_V4` | — | Yes | Public IPv4 address for the Azure Load Balancer |
| `PUBLIC_IP_V6` | — | Yes | Public IPv6 address for the Azure Load Balancer |
| `AKS_VNET_IPV4_CIDR` | — | Yes | Full AKS VNet IPv4 CIDR; trusted for `X-Forwarded-For` |
| `AKS_VNET_IPV6_CIDR` | — | Yes | Full AKS VNet IPv6 CIDR; trusted for `X-Forwarded-For` |
| `EXTERNAL_TRAFFIC_POLICY` | `Local` | No | Service `externalTrafficPolicy` |
| `OTEL_ENDPOINT` | `otel-collector.monitoring.svc.cluster.local:4317` | No | OTLP gRPC endpoint for logs, metrics, and traces |
| `DEFAULT_GATEWAY_HOSTNAME` | — | multitenancy only | Hostname for the default Gateway listeners |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No (policies only) | AKS pod network IPv4 CIDR for Linkerd NetworkAuthentication |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No (policies only) | AKS pod network IPv6 CIDR for Linkerd NetworkAuthentication |

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and `traefik` namespace; 3 replicas, dual-stack Load Balancer, Linkerd injection, OTLP telemetry, TLS 1.2+ |
| `apps` | Standard variant; enables Traefik CRD provider, HSTS applied at entrypoint level via `hsts-header` middleware (`traefik` and `default` namespaces), root catch-all `IngressRoute` returns 418 for unmatched paths |
| `adminservices` | Gateway API variant (CRD provider also enabled); same HSTS and catch-all setup as `apps`, stays in `traefik` namespace, no Linkerd policies |
| `multitenancy` | Gateway API variant; Flux resources in `platform-system`, `kubernetesCRD` disabled, four Gateway listeners (http/https + wildcard), Linkerd policies included. **No central HSTS** — `kubernetesCRD` is disabled so `Middleware` CRDs cannot be resolved; HSTS must be applied via `ResponseHeaderModifier` filters on individual `HTTPRoute` resources in downstream apps |
| `policies` | Linkerd `Server`, `NetworkAuthentication`, and `AuthorizationPolicy` resources for kubelet probes and proxy admin in deny-all mesh environments; see [`policies/README.md`](policies/README.md) |

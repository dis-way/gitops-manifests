# Traefik

Deploys Traefik as the ingress controller for the Altinn platform via Flux HelmRelease (chart v39+).

CRDs (Traefik and Gateway API standard channel) are managed directly by the HelmRelease via `install/upgrade.crds: CreateReplace`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_NODE_RG` | — | Yes | Azure Resource Group for AKS nodes (Load Balancer annotation) |
| `PUBLIC_IP_V4` | — | Yes | Public IPv4 address for the Azure Load Balancer |
| `PUBLIC_IP_V6` | — | Not platform-aks / eformidling-aks | Public IPv6 address for the Azure Load Balancer |
| `AKS_VNET_IPV4_CIDR` | — | Not platform-aks / eformidling-aks | Full AKS VNet IPv4 CIDR; trusted for `X-Forwarded-For` |
| `AKS_VNET_IPV6_CIDR` | — | Not platform-aks / eformidling-aks | Full AKS VNet IPv6 CIDR; trusted for `X-Forwarded-For` |
| `AKS_SYSTEM_SUBNET_CIDR` | — | platform-aks / eformidling-aks | AKS system node subnet CIDR; trusted for `X-Forwarded-For` |
| `AKS_WORK_SUBNET_CIDR` | — | platform-aks / eformidling-aks | AKS work node subnet CIDR; trusted for `X-Forwarded-For` |
| `AKS_FILESCAN_SUBNET_CIDR` | — | platform-aks only | AKS filescan node subnet CIDR; trusted for `X-Forwarded-For` |
| `LB_SOURCE_RANGE_APIM` | `127.0.0.1/32` | platform-aks / eformidling-aks / multitenancy | Load Balancer source range CIDR for API Management IPv4 (e.g. `1.2.3.4/32`); defaults to loopback when APIM has no IPv4 |
| `LB_SOURCE_RANGE_APIM_IPV6` | `::1/128` | multitenancy | Load Balancer source range CIDR for API Management IPv6; defaults to loopback when APIM has no IPv6 |
| `LB_SOURCE_RANGE_CORRESPONDENCE` | — | platform-aks only | Load Balancer source range CIDR for correspondence outbound IP |
| `EXTERNAL_TRAFFIC_POLICY` | `Local` | No | Service `externalTrafficPolicy` |
| `OTEL_ENDPOINT` | `otel-collector.monitoring.svc.cluster.local:4317` | No | OTLP gRPC endpoint for logs, metrics, and traces |
| `DEFAULT_GATEWAY_HOSTNAME` | — | multitenancy only | Hostname for the default Gateway listeners |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No (policies only) | AKS pod network IPv4 CIDR for Linkerd NetworkAuthentication |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No (policies only) | AKS pod network IPv6 CIDR for Linkerd NetworkAuthentication |
| `UAMI_CERT_MANAGER_CLIENT_ID` | — | platform-aks / eformidling-aks post-deploy | Managed identity client ID for cert-manager DNS-01 solver |
| `CERT_DNS_NAME` | — | platform-aks / eformidling-aks post-deploy | Full DNS name for the TLS certificate (e.g. `internal.platform.prod.altinn.cloud`) |
| `KV_SECRET_NAME_CERT` | — | apps post-deploy | Key Vault secret name holding the TLS certificate, pulled into `tls.crt` of the `ssl-cert` secret |
| `KV_SECRET_NAME_KEY` | — | apps post-deploy | Key Vault secret name holding the TLS private key, pulled into `tls.key` of the `ssl-cert` secret |
| `CERT_KV_UAMI_CLIENT_ID` | — | apps post-deploy | Managed identity client ID (federated to the `dis-tls-cert-kv-uami` SA in `traefik`) with read access to the `dis-tls-cert` Key Vault |
| `CERT_KV_TENANT_ID` | `cd0026d8-283b-4a55-9bfa-d0ef4a8ba21c` | No | Azure tenant ID for the `dis-tls-cert-kv-uami` workload identity |

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and `traefik` namespace; 3 replicas, dual-stack Load Balancer, Linkerd injection, OTLP telemetry, TLS 1.2+ |
| `platform-aks` | AKS platform overlay; IPv4 single-stack, adds `loadBalancerSourceRanges` (APIM + correspondence IPs), Prometheus ServiceMonitor, and HSTS middleware |
| `apps` | Standard variant; enables Traefik CRD provider, HSTS applied at entrypoint level via `hsts-header` middleware (`traefik` and `default` namespaces), root catch-all `IngressRoute` returns 418 for unmatched paths |
| `adminservices` | Gateway API variant (CRD provider also enabled); same HSTS and catch-all setup as `apps`, stays in `traefik` namespace, no Linkerd policies |
| `multitenancy` | Gateway API variant; Flux resources in `platform-system`, `kubernetesCRD` disabled, four Gateway listeners (http/https + wildcard), Linkerd policies included. Restricts `loadBalancerSourceRanges` to Cloudflare, altinn-uptime, and APIM via a ConfigMap (`valuesFrom`); Cloudflare ranges are updated automatically by the `update-cloudflare-ips` workflow. **No central HSTS** — `kubernetesCRD` is disabled so `Middleware` CRDs cannot be resolved; HSTS must be applied via `ResponseHeaderModifier` filters on individual `HTTPRoute` resources in downstream apps |
| `eformidling-aks` | eFormidling AKS overlay; IPv4 single-stack, adds `loadBalancerSourceRanges` (APIM IP), and HSTS middleware |
| `policies` | Linkerd `Server`, `NetworkAuthentication`, and `AuthorizationPolicy` resources for kubelet probes and proxy admin in deny-all mesh environments; see [`policies/README.md`](policies/README.md) |
| `post-deploy` | Manifests applied after the deployment has reconciled |
| `platform-aks/post-deploy` | Manifests applied after the deployment has reconciled |
| `eformidling-aks/post-deploy` | Manifests applied after the deployment has reconciled |
| `apps/post-deploy` | Manifests applied after the deployment has reconciled |
| `adminservices/post-deploy` | Manifests applied after the deployment has reconciled |
| `multitenancy/post-deploy` | Manifests applied after the deployment has reconciled |

# Traefik Configuration

This directory contains the Flux configuration for deploying Traefik as the ingress controller in the Altinn platform. The configuration supports two distinct deployment models: **Apps** (Standard) and **Multitenancy**.

## Overview

Traefik serves as a reverse proxy and load balancer, handling incoming traffic routing for the Altinn platform. The deployment is managed via Flux CD and is designed for high availability, security, and observability.

## Directory Structure

```text
.
├── base/                   # Shared base configuration
│   ├── helmrelease.yaml    # Core Traefik HelmRelease
│   ├── helmrepository.yaml # Traefik HelmRepository
│   └── namespace.yaml      # 'traefik' namespace definition
├── apps/                   # Standard deployment variant
│   ├── kustomization.yaml
│   └── extraObjects-patch.yaml
├── multitenancy/           # Multitenancy deployment variant
│   └── kustomization.yaml
├── policies/               # Linkerd policies for multitenancy
│   ├── linkerd-policies.yaml
│   └── README.md
└── README.md
```

## Deployment Variants

### 1. Standard (`apps`)
The standard deployment model used for typical application clusters.
-   **Routing**: Uses Traefik's `IngressRoute` CRD.
-   **Namespace**: Resources are managed in and deployed to the `traefik` namespace.
-   **Network Trust**: Trusts specific AKS System and Worker pool IP ranges.
-   **Middleware**: Includes HSTS headers and a root catch-all redirect.

### 2. Multitenancy (`multitenancy`)
The deployment model designed for multi-tenant environments using the Gateway API.
-   **Routing**: Uses Kubernetes **Gateway API** (`kubernetesGateway`). `IngressRoute` (CRD) is disabled.
-   **Namespace**: Flux resources (`HelmRelease`, `HelmRepository`) reside in `platform-system` (management plane), while the Traefik workload runs in `traefik`.
-   **Network Trust**: Trusts the entire AKS VNet CIDR.
-   **Security**: Integrates with specific Linkerd policies (from `policies/`) to secure health probes and admin access in a restrictive mesh environment.

## Key Configuration Features

### High Availability & Security
-   **Replicas**: 3 instances with Pod Disruption Budget (min 1 available).
-   **Network**: Dual-stack (IPv4/IPv6) support. Azure Load Balancer with dedicated public IPs.
-   **TLS**: Minimum TLS 1.2 with strong cipher suites.
-   **Service Mesh**: Full Linkerd injection and configuration.

### Observability (OTLP)
Traefik is configured to export telemetry via OTLP to a collector:
-   **Logs, Metrics, Traces**: All enabled and sent to `otel-collector.monitoring.svc.cluster.local:4317` (configurable via `OTEL_ENDPOINT`).
-   **Prometheus**: Standard Prometheus metrics are replaced/augmented by OTLP.

## Port Configuration

Traefik uses custom internal ports to avoid running as root and to align with Linkerd requirements, mapping them to standard external ports.

| Internal Port | External Port | Protocol | Purpose |
|---------------|---------------|----------|---------|
| `8000` | `80` | TCP | HTTP (Redirects to HTTPS) |
| `8443` | `443` | TCP | HTTPS (TLS Enabled) |

## Environment Variables

The configuration relies on Flux post-build variable substitution. Required variables depend on the deployment variant.

### Common Variables
| Variable | Description | Default/Example |
|----------|-------------|-----------------|
| `AKS_NODE_RG` | Azure Resource Group for AKS nodes | `rg-aks-nodes` |
| `PUBLIC_IP_V4` | Public IPv4 address for Load Balancer | `20.x.x.x` |
| `PUBLIC_IP_V6` | Public IPv6 address for Load Balancer | `2603:x:x:x::` |
| `EXTERNAL_TRAFFIC_POLICY` | Service external traffic policy | `Local` |
| `OTEL_ENDPOINT` | OTLP Collector endpoint | `otel-collector...:4317` |

### Standard (`apps`) Specific
| Variable | Description |
|----------|-------------|
| `AKS_SYSP00L_IP_PREFIX_0` | AKS System Pool IP Prefix |
| `AKS_SYSP00L_IP_PREFIX_1` | AKS System Pool IP Prefix |
| `AKS_WORKPOOL_IP_PREFIX_0` | AKS Worker Pool IP Prefix |
| `AKS_WORKPOOL_IP_PREFIX_1` | AKS Worker Pool IP Prefix |

### Multitenancy (`multitenancy`) Specific
| Variable | Description |
|----------|-------------|
| `AKS_VNET_IPV4_CIDR` | Full AKS VNet IPv4 CIDR |
| `AKS_VNET_IPV6_CIDR` | Full AKS VNet IPv6 CIDR |
| `DEFAULT_GATEWAY_HOSTNAME`| Hostname for the default Gateway listener |

## Policies (Multitenancy)
The `policies/` directory contains Linkerd `Server`, `NetworkAuthentication`, and `AuthorizationPolicy` resources. These are critical for the multitenancy setup to allow:
-   Kubelet health probes (liveness/readiness).
-   Proxy admin access (localhost).
-   Prometheus scraping (if not using OTLP exclusively for this path).

These policies ensure Traefik remains operational even when the cluster enforces a default "deny-all" inbound policy.

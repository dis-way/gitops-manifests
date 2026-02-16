# Whoami Linkerd Policies

Authorization policies for securing the whoami service when using restrictive Linkerd inbound policies.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), these policies explicitly allow:

1. **Meshed traffic** - Any meshed pod can reach the whoami service
2. **Health checks** - Kubelet can perform liveness/readiness probes via the proxy admin port

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Traefik Ingress   │     │       kubelet       │
│   (meshed pod)      │     │ (Pod + VNET CIDRs)  │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ MeshTLSAuthentication│    │ NetworkAuthentication│
│   "any-meshed-pod"  │     │      "kubelet"      │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ AuthorizationPolicy │     │ AuthorizationPolicy │
│    "whoami-http"    │     │ "whoami-proxy-admin"│
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│       Server        │     │       Server        │
│  "whoami-http" :80  │     │ "whoami-proxy-admin"│
└─────────────────────┘     └─────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kubelet` | NetworkAuthentication | Allows traffic from pod and VNET CIDRs (for health probes) |
| `any-meshed-pod` | MeshTLSAuthentication | Allows any pod with valid mesh identity |

### Servers

| Server | Port | Protocol | Purpose |
|--------|------|----------|---------|
| `whoami-http` | 80 | HTTP/1 | Main application traffic |
| `whoami-proxy-admin` | linkerd-admin | HTTP/1 | Proxy health checks |

### AuthorizationPolicies

| Policy | Target Server | Authentication | Purpose |
|--------|---------------|----------------|---------|
| `whoami-http-mesh` | whoami-http | MeshTLSAuthentication | Allow meshed traffic |
| `whoami-proxy-admin` | whoami-proxy-admin | NetworkAuthentication | Allow kubelet health probes |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| HTTP traffic blocked | Ingress cannot reach whoami, 503 errors |
| Health checks blocked | Pods restart in a loop, marked as unhealthy |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS overlay pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS overlay pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR |

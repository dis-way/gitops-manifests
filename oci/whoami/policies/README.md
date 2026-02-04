# Whoami Linkerd Policies

Authorization policies for securing the whoami service when using restrictive Linkerd inbound policies.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), these policies explicitly allow:

1. **Meshed traffic** - Traefik ingress (meshed) can reach the whoami service
2. **Health checks** - Kubelet can perform liveness/readiness probes via the proxy admin port

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Traefik Ingress   │     │       kubelet       │
│   (meshed pod)      │     │    (VNET CIDRs)     │
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
| `kubelet` | NetworkAuthentication | Allows traffic from VNET CIDRs (for health probes) |
| `any-meshed-pod` | MeshTLSAuthentication | Allows any pod with valid mesh identity |

### Servers

| Server | Port | Protocol | Purpose |
|--------|------|----------|---------|
| `whoami-http` | 80 | HTTP/1 | Main application traffic |
| `whoami-proxy-admin` | linkerd-admin | HTTP/1 | Proxy health checks |

### AuthorizationPolicies

| Policy | Target Server | Authentication | Purpose |
|--------|---------------|----------------|---------|
| `whoami-http` | whoami-http | MeshTLSAuthentication | Allow meshed ingress traffic |
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
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for kubelet health checks) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for kubelet health checks) |

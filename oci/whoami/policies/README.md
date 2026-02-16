# Whoami Linkerd Policies

Authorization policies for securing the whoami service when using restrictive Linkerd inbound policies.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), these policies explicitly allow:

1. **Meshed traffic** - Any meshed pod can reach the whoami service (all paths)
2. **Health checks** - Kubelet can perform liveness/readiness probes (`/health` on port 80 and proxy admin port)

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Traefik Ingress   │     │       kubelet       │
│   (meshed pod)      │     │ (Pod + VNET CIDRs)  │
└──────────┬──────────┘     └─────────┬───────────┘
           │                      ┌───┴───┐
           ▼                      ▼       ▼
┌─────────────────────┐  ┌────────────┐ ┌─────────────────────┐
│ MeshTLSAuthentication│  │ Network-   │ │ NetworkAuthentication│
│   "any-meshed-pod"  │  │ Auth       │ │      "kubelet"      │
└──────────┬──────────┘  │ "kubelet"  │ └──────────┬──────────┘
           │             └─────┬──────┘            │
           ▼                   ▼                   ▼
┌─────────────────────┐ ┌──────────────────┐ ┌─────────────────────┐
│ AuthorizationPolicy │ │AuthorizationPolicy│ │ AuthorizationPolicy │
│  "whoami-http-mesh" │ │"whoami-health-   ││ "whoami-proxy-admin"│
│                     │ │       kubelet"   │ │                     │
└──────────┬──────────┘ └────────┬─────────┘ └──────────┬──────────┘
           │                     │                      │
           ▼                     ▼                      ▼
┌─────────────────────┐ ┌──────────────────┐ ┌─────────────────────┐
│     HTTPRoute       │ │    HTTPRoute     │ │       Server        │
│   "whoami-mesh"     │ │  "whoami-health" │ │ "whoami-proxy-admin"│
│   (all paths)       │ │  (/health only)  │ │                     │
└──────────┬──────────┘ └────────┬─────────┘ └─────────────────────┘
           │                     │
           ▼                     ▼
┌──────────────────────────────────────────┐
│                 Server                   │
│           "whoami-http" :80              │
└──────────────────────────────────────────┘
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

### HTTPRoutes

| Route | Parent | Match | Purpose |
|-------|--------|-------|---------|
| `whoami-mesh` | Server `whoami-http` | `PathPrefix: /` | Catch-all route for meshed traffic |
| `whoami-health` | Server `whoami-http` | `/health` | Health check route for kubelet |

### AuthorizationPolicies

| Policy | Target | Authentication | Purpose |
|--------|--------|----------------|---------|
| `whoami-http-mesh` | HTTPRoute `whoami-mesh` | MeshTLSAuthentication | Allow meshed traffic to all paths |
| `whoami-health-kubelet` | HTTPRoute `whoami-health` | NetworkAuthentication | Allow kubelet health probes to `/health` |
| `whoami-proxy-admin` | Server `whoami-proxy-admin` | NetworkAuthentication | Allow kubelet proxy admin health probes |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| HTTP traffic blocked | Ingress cannot reach whoami, 503 errors |
| Health checks blocked | Pods restart in a loop, marked as unhealthy |

With `v1beta3` Server resources, once any `policy.linkerd.io` HTTPRoute is attached to a Server, only requests matching a defined route are allowed. This is why both `whoami-mesh` (catch-all) and `whoami-health` routes are needed - without the catch-all, non-health requests would be rejected with `no route found for request`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS overlay pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS overlay pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR |

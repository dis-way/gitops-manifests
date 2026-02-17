# Traefik Policies

Linkerd policies for securing Traefik components.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), traffic to Traefik is blocked. These policies explicitly allow:

2. **Health checks** - kubelet needs to perform liveness/readiness probes
3. **Proxy health** - kubelet needs to probe the Linkerd proxy sidecar on meshed pods

## Architecture

```
┌─────────────────────┐
│       kubelet       │
│ (Pod + VNET CIDRs)  │
└──────────┬──────────┘
           │
           ▼
┌──────────────────────┐
│ NetworkAuthentication│
│       "kubelet"      │
└──────────┬───────────┘
           │
           ▼
┌───────────────────────────┐
│    AuthorizationPolicy    │
│"aso-health", "proxy-admin"│
└──────────┬────────────────┘
           │
           ▼
┌───────────────────────────┐
│          Server           │
│"aso-health", "proxy-admin"│
└───────────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kubelet` | NetworkAuthentication | Allows traffic from pod and VNET CIDRs (for health probes) |

### Health Check Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `traefik-health` | traefik | traefik | Traefik container health |

### Proxy Admin Server

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `proxy-admin` | all pods | 4191 | Linkerd proxy sidecar health checks |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| Health checks blocked | Traefik pods restart in a loop |
| Proxy admin blocked | Meshed pods fail kubelet health checks |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS pod network IPv4 CIDR (overlay networking) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS pod network IPv6 CIDR (overlay networking) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for API server and kubelet) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for API server and kubelet) |

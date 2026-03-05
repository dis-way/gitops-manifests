# OpenCost Policies

Linkerd policies for securing OpenCost components and allowing health probes.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), traffic to OpenCost is blocked. These policies explicitly allow:

1. **Health checks** - kubelet needs to perform liveness/readiness probes on port 9003
2. **Proxy health** - kubelet needs to probe the Linkerd proxy sidecar on meshed pods (port 4191)

## Architecture

```
┌─────────────────────┐
│       kubelet       │
│    (VNET CIDRs)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ NetworkAuthentication│
│      "kubelet"      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ AuthorizationPolicy │
│  (health + proxy)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│       Server        │
│ (HTTP/1 9003/4191)  │
└─────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kubelet` | NetworkAuthentication | Allows traffic from VNET CIDRs (for health probes) |

### Health Check Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `opencost-health` | opencost | 9003 | OpenCost container health |

### Proxy Admin Server

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `proxy-admin` | all pods | 4191 | Linkerd proxy sidecar health checks |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for kubelet) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for kubelet) |

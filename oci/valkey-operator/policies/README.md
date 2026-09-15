# valkey-operator Linkerd Policies

Linkerd policies for the valkey-operator pod, which runs in the mesh.

## Overview

The clusters run linkerd with default inbound policy `deny`. A meshed pod rejects every connection until a `Server` and an `AuthorizationPolicy` allow it. These policies allow:

1. **Health checks** - kubelet reaches the liveness and readiness probes of the operator and of its proxy
2. **Metrics** - the Azure Monitor scraper, which is not meshed, reaches the metrics port

The operator's own connections to the Valkey pods need no rule here. dis-cache-operator allows the operator identity on every cache it creates.

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│       kubelet       │     │   metrics scraper   │
│    (VNET CIDRs)     │     │     (pod CIDRs)     │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ NetworkAuthentication│    │ NetworkAuthentication│
│      "kubelet"      │     │   "cluster-pods"    │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ AuthorizationPolicy │     │ AuthorizationPolicy │
│  (health, proxy)    │     │      (metrics)      │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│       Server        │     │       Server        │
│ health, linkerd-admin│    │    metrics (TLS)    │
└─────────────────────┘     └─────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kubelet` | NetworkAuthentication | Allows traffic from VNET CIDRs (for health probes) |
| `cluster-pods` | NetworkAuthentication | Allows traffic from pod CIDRs (for the metrics scraper) |

### Servers

| Server | Port | Protocol | Purpose |
|--------|------|----------|---------|
| `valkey-operator-health` | health | HTTP/1 | Operator liveness and readiness probes |
| `valkey-operator-proxy-admin` | linkerd-admin | HTTP/1 | Proxy liveness and readiness probes |
| `valkey-operator-metrics` | metrics | TLS | Operator metrics; the port checks tokens itself |

### AuthorizationPolicies

| Policy | Server | Authentication |
|--------|--------|----------------|
| `valkey-operator-health` | `valkey-operator-health` | `kubelet` |
| `valkey-operator-proxy-admin` | `valkey-operator-proxy-admin` | `kubelet` |
| `valkey-operator-metrics` | `valkey-operator-metrics` | `cluster-pods` |

## Why This Matters

| Failure Mode | Symptom |
|--------------|---------|
| Health checks blocked | The operator pod restarts in a loop, no Valkey cluster is reconciled |
| Metrics blocked | No operator metrics in Azure Monitor |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for kubelet) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for kubelet) |

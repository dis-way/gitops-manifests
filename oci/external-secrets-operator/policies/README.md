# External Secrets Policies

Linkerd policies for securing External Secrets Operator components.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), traffic to the External Secrets Operator is blocked. These policies explicitly allow:

1. **Webhook access** - kube-apiserver needs to reach validation/mutation webhooks
2. **Health checks** - kubelet needs to perform liveness/readiness probes
3. **Proxy health** - kubelet needs to probe the Linkerd proxy sidecar on meshed pods

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   kube-apiserver    │     │       kubelet       │
│  (pod + VNET CIDRs) │     │    (VNET CIDRs)     │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ NetworkAuthentication│    │ NetworkAuthentication│
│  "kube-api-server"  │     │      "kubelet"      │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│ AuthorizationPolicy │     │ AuthorizationPolicy │
│   (webhook access)  │     │  (health + proxy)   │
└──────────┬──────────┘     └──────────┬──────────┘
           │                           │
           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│       Server        │     │       Server        │
│   (TLS :10250)      │     │ (HTTP/1 ready/4191) │
└─────────────────────┘     └─────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kube-api-server` | NetworkAuthentication | Allows traffic from pod and VNET CIDRs (for webhooks) |
| `kubelet` | NetworkAuthentication | Allows traffic from VNET CIDRs (for health probes) |

### Webhook Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `external-secrets-webhook` | webhook | 10250 | Validating/mutating webhook |

### Health Check Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `external-secrets-webhook-health` | webhook | ready | Webhook container health |
| `external-secrets-cert-controller-health` | cert-controller | ready | Cert-controller container health |
| `external-secrets-controller-health` | controller | ready | Main controller container health |

### Proxy Admin Server

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `proxy-admin` | all pods | 4191 | Linkerd proxy sidecar health checks |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| Webhook blocked | ExternalSecret resources rejected, secrets not synced |
| Health checks blocked | Operator pods restart in a loop |
| Proxy admin blocked | Meshed pods fail kubelet health checks |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for API server and kubelet) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for API server and kubelet) |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./policies
  postBuild:
    substitute:
      AKS_VNET_IPV4_CIDR: "10.205.0.0/16"
      AKS_VNET_IPV6_CIDR: "fd12:2291:d70a::/56"
```

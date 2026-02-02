# Linkerd Policies

Network policies for securing Linkerd control plane webhooks.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), the kube-apiserver's webhook calls are blocked because they don't have Linkerd mesh identity. These policies explicitly allow the apiserver to reach the webhooks based on source IP.

## Architecture

```
┌─────────────────────┐
│   kube-apiserver    │
│  (from pod CIDRs)   │
└──────────┬──────────┘
           │ TLS :8443
           ▼
┌─────────────────────────────────────────────────────┐
│              NetworkAuthentication                  │
│              "kube-api-server"                      │
│         (allows traffic from pod CIDRs)            │
└──────────┬──────────────────────────────┬──────────┘
           │                              │
           ▼                              ▼
┌─────────────────────┐    ┌─────────────────────────┐
│ AuthorizationPolicy │    │   AuthorizationPolicy   │ (x3)
│  (references auth)  │    │                         │
└──────────┬──────────┘    └────────────┬────────────┘
           │                            │
           ▼                            ▼
┌─────────────────────┐    ┌─────────────────────────┐
│       Server        │    │         Server          │ (x3)
│ (defines endpoint)  │    │                         │
└─────────────────────┘    └─────────────────────────┘
```

## Resources Explained

### Server (x3)

Defines protected endpoints on Linkerd control plane pods:

| Server | Component | Purpose |
|--------|-----------|---------|
| `proxy-injector-webhook` | proxy-injector | Mutating webhook that injects sidecar proxies |
| `sp-validator-webhook` | sp-validator | Validates ServiceProfile resources |
| `policy-validator-webhook` | policy-validator | Validates Linkerd policy resources |

All listen on port 8443 with TLS.

### AuthorizationPolicy (x3)

Links each Server to the `NetworkAuthentication`. Only traffic that passes the network authentication is allowed to reach these webhooks.

### NetworkAuthentication

Defines which source IPs are trusted. Here it's the pod CIDRs because the kube-apiserver calls webhooks from within the cluster network (specifically from nodes running pods).

## Why This Matters

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), the kube-apiserver's webhook calls would be blocked because they don't have Linkerd mesh identity. This policy explicitly allows the apiserver to reach the webhooks based on source IP, ensuring:

- Pod injection continues working (proxy-injector)
- ServiceProfile validation works (sp-validator)
- Policy resource validation works (policy-validator)

Without this, deploying any workload or Linkerd policy would fail when the apiserver can't reach the webhooks.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | AKS pod IPv4 CIDR for kube-apiserver network authentication |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | AKS pod IPv6 CIDR for kube-apiserver network authentication |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: ./policies
  postBuild:
    substitute:
      AKS_POD_IPV4_CIDR: "10.240.0.0/16"
      AKS_POD_IPV6_CIDR: "fd10:59f0:8c79:240::/64"
```

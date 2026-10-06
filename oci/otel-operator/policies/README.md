# OTel Operator Policies

Linkerd policies for securing the OpenTelemetry Operator's admission webhook.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), traffic to the OpenTelemetry Operator is blocked. These policies explicitly allow:

1. **Webhook access** - kube-apiserver needs to reach the operator's mutating, validating and CRD conversion webhooks

Health checks and the proxy admin port are not covered here: no `Server` selects those ports, so they keep the default inbound policy.

## Architecture

```
┌───────────────────────┐
│    kube-apiserver     │
│   (pod + VNET CIDRs)  │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│ NetworkAuthentication │
│   "kube-api-server"   │
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│  AuthorizationPolicy  │
│"otel-operator-webhook"│
└───────────┬───────────┘
            │
            ▼
┌───────────────────────┐
│        Server         │
│"otel-operator-webhook"│
│ (TLS, webhook-server) │
└───────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kube-api-server` | NetworkAuthentication | Allows traffic from pod and VNET CIDRs (for webhooks) |

### Webhook Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `otel-operator-webhook` | controller-manager | webhook-server | Pod SDK injection, `Instrumentation` and `OpenTelemetryCollector` defaulting/validation, collector CRD conversion |

### AuthorizationPolicies

| Policy | Server | Authentication |
|--------|--------|----------------|
| `otel-operator-webhook` | `otel-operator-webhook` | `kube-api-server` |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| Pod webhook blocked | Annotated pods start without the `OTEL_*` environment, silently — `mpod.kb.io` fails open |
| CR webhooks blocked | `Instrumentation` and `OpenTelemetryCollector` writes and dry-runs rejected, so Flux cannot reconcile any of `oci/otel-collector` |
| Conversion webhook blocked | `OpenTelemetryCollector` requests that need `v1alpha1` ↔ `v1beta1` conversion fail |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for API server) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for API server) |

# Linkerd Policies

Network policies for securing Linkerd control plane components.

## Overview

When using a restrictive `DEFAULT_INBOUND_POLICY` (like `cluster-authenticated` or `deny`), traffic to the Linkerd control plane is blocked. These policies explicitly allow:

1. **Webhook access** - kube-apiserver needs to reach validation/mutation webhooks
2. **Health checks** - kubelet needs to perform liveness/readiness probes
3. **Mesh communication** - proxies need to reach identity and destination services

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   kube-apiserver    │     │       kubelet       │     │    mesh proxies     │
│ (pod + node CIDRs)  │     │    (node CIDRs)     │     │   (mTLS identity)   │
└──────────┬──────────┘     └──────────┬──────────┘     └──────────┬──────────┘
           │                           │                           │
           ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ NetworkAuthentication│    │ NetworkAuthentication│    │ MeshTLSAuthentication│
│  "kube-api-server"  │     │      "kubelet"      │     │   "any-meshed-pod"  │
└──────────┬──────────┘     └──────────┬──────────┘     └──────────┬──────────┘
           │                           │                           │
           ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│ AuthorizationPolicy │     │ AuthorizationPolicy │     │ AuthorizationPolicy │
│   (webhook access)  │     │  (health checks)    │     │   (gRPC services)   │
└──────────┬──────────┘     └──────────┬──────────┘     └──────────┬──────────┘
           │                           │                           │
           ▼                           ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│       Server        │     │       Server        │     │       Server        │
│  (TLS :8443/9443)   │     │  (HTTP/1 admin)     │     │    (gRPC ports)     │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

## Resources

### Authentication

| Resource | Type | Purpose |
|----------|------|---------|
| `kube-api-server` | NetworkAuthentication | Allows traffic from pod and node CIDRs (for webhooks) |
| `kubelet` | NetworkAuthentication | Allows traffic from node CIDRs (for health probes) |
| `any-meshed-pod` | MeshTLSAuthentication | Allows any pod with valid mesh identity |

### Webhook Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `proxy-injector-webhook` | proxy-injector | 8443 | Mutating webhook for sidecar injection |
| `sp-validator-webhook` | destination | sp-validator | Validates ServiceProfile resources |
| `policy-validator-webhook` | destination | policy-https | Validates Linkerd policy resources |

### Health Check Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `destination-admin` | destination | dest-admin | Destination container health |
| `destination-policy-admin` | destination | policy-admin | Policy container health |
| `destination-spval-admin` | destination | spval-admin | SP-validator container health |
| `proxy-injector-admin` | proxy-injector | injector-admin | Proxy-injector health |
| `identity-admin` | identity | ident-admin | Identity health |

### Mesh Internal Servers

| Server | Component | Port | Purpose |
|--------|-----------|------|---------|
| `identity-grpc` | identity | ident-grpc | Proxies obtain TLS certificates |
| `destination-grpc` | destination | dest-grpc | Proxies get service discovery info |
| `policy-grpc` | destination | policy-grpc | Proxies get policy updates |

## Why This Matters

Without these policies, the following will fail when using restrictive inbound policies:

| Failure Mode | Symptom |
|--------------|---------|
| Webhook blocked | Pod deployments fail, policy resources rejected |
| Health checks blocked | Control plane pods restart in a loop |
| Identity gRPC blocked | Proxy sidecars can't obtain TLS certificates |
| Destination gRPC blocked | Proxies can't discover services or routes |

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR |
| `AKS_NODE_IPV4_CIDR` | - | Yes | Node network IPv4 CIDR |
| `AKS_NODE_IPV6_CIDR` | - | Yes | Node network IPv6 CIDR |

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
      AKS_NODE_IPV4_CIDR: "10.205.0.0/16"
      AKS_NODE_IPV6_CIDR: "fd12:2291:d70a::/56"
```

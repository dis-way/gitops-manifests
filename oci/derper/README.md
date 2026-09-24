# Derper

Standalone Tailscale DERP relay and STUN server for the headscale tailnet. Clients are admitted only if headscale knows their node key (`--verify-client-url`).

The image is built from `tailscale.com/cmd/derper` in [dis-way/adminservices](https://github.com/dis-way/adminservices/tree/main/images/derper) and pulled through the `altinncr` ghcr.io cache.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DERP_HOSTNAME` | - | Yes | Public hostname of the relay, e.g. `derp-admin-test.altinn.cloud`. Used by the Gateway, HTTPRoute and certificate |
| `AKS_NODE_RG` | - | Yes | Azure node resource group containing the public IP (shared with Traefik) |
| `PUBLIC_IP_V4` | - | Yes | Public IPv4 address for the STUN LoadBalancer (shared with Traefik) |
| `PUBLIC_IP_V6` | - | Yes | Public IPv6 address for the STUN LoadBalancer (shared with Traefik) |
| `HEADSCALE_URL` | `https://headscale.altinn.cloud` | No | Headscale server URL. derper calls `<HEADSCALE_URL>/verify` to admit clients |

## Layers

| Path | Description |
|------|-------------|
| `.` | Core resources: namespace, deployment, services, gateway, and HTTPRoute |
| `post-deploy` | cert-manager Certificate for Let's Encrypt TLS |

## Design notes

- Traefik terminates TLS on 443 and forwards the DERP HTTP upgrade to derper on port 3340. The headscale embedded DERP runs the same way.
- STUN (UDP 3478) uses a LoadBalancer Service with `externalTrafficPolicy: Local`. STUN must see the real client address, so the traffic must not be SNATed.
- Run one replica per cluster and add each cluster as its own region in the headscale DERP map. Two replicas behind one load balancer cannot relay between each other without DERP mesh mode.
- `/debug/` is only served to loopback and Tailscale addresses, so it returns 403 through Traefik.

## Prerequisites

### DNS

Two records are required in the `altinn.cloud` zone:

1. **Service record** — points the hostname at the Traefik load balancer:

```text
<DERP_HOSTNAME>  A     <PUBLIC_IP_V4>
<DERP_HOSTNAME>  AAAA  <PUBLIC_IP_V6>
```

2. **ACME delegation** — delegates the DNS-01 challenge to the Azure DNS zone managed by cert-manager in the cluster:

```text
_acme-challenge.<DERP_HOSTNAME>  CNAME  _acme-challenge.<DERP_HOSTNAME>.<cluster child zone>
```

### ghcr.io package visibility

The `altinncr` ghcr.io cache rule has no credential set, so `ghcr.io/dis-way/derper` must be public.

### Headscale DERP map

Add the relay as a region in the headscale DERP map (`oci/headscale`). Clients only use regions that headscale sends them.

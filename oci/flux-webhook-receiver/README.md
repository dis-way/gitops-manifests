# Flux Webhook Receiver

Exposes the Flux notification-controller webhook receiver through the Traefik Gateway, so a publishing workflow can ask Flux to reconcile a `Receiver` right after it pushes an artifact.

The route serves `https://flux-webhook.<DEFAULT_GATEWAY_HOSTNAME>/hook/<digest>` and forwards to the `webhook-receiver` Service that Flux installs in `flux-system`. It adds no authentication of its own: each `Receiver` authenticates its callers. Product teams must use `Receiver` type `generic-oidc` (Flux 2.9 or later), which verifies the caller's OIDC token; the path of such a `Receiver` is not a secret.

The Traefik load balancer source ranges still apply. A caller outside those ranges cannot reach the route.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_GATEWAY_HOSTNAME` | - | Yes | DNS zone of the cluster's Traefik Gateway; the route answers on `flux-webhook.<zone>` |

## Layers

| Path | Description |
|------|-------------|
| `base` | `HTTPRoute` in `flux-system` on the `https-wildcard` listener of `traefik-gateway` |
| `multitenancy` | Entry point for the multi-tenant clusters; same as `base` |

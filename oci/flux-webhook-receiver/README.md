# Flux Webhook Receiver

Routes reconcile requests from the DIS edge gateway to the Flux notification-controller in a DIS core cluster, for on-demand Flux reconcile ([RFC 0017](https://github.com/Altinn/altinn-platform/blob/main/rfcs/0017-on-demand-flux-reconcile.md)).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_GATEWAY_HOSTNAME` | - | Yes | DNS zone of the cluster's Traefik Gateway. The route answers on `flux-webhook.<DEFAULT_GATEWAY_HOSTNAME>` |

## Layers

| Path | Description |
|------|-------------|
| `multitenancy` | DIS core cluster: the route, the network policy and the admission policy below. The root `kustomization.yaml` builds this layer |

## Notes

- **Enable.** The flag `enable_flux_webhook_receiver` of the `dis_aks_resources_multitenancy` module in `terraform-azurerm-dis-modules` deploys this package. The same flag selects the `multitenancy-flux-webhook` layer of `oci/traefik` (3.18.0 or later), which adds the listener that the route needs.
- **Route.** The `HTTPRoute` `flux-webhook-receiver` in `flux-system` attaches only to the `flux-webhook` listener of `traefik-gateway`. That listener's Service admits only the DIS edge outbound ranges on port 9443. The route matches only `POST` with the path prefix `/hook`, and it does not rewrite the path, because the notification-controller finds the `Receiver` by the exact path. The route assumes that `flux-system` is outside the Linkerd mesh, so it sets no `l5d-dst-override` header.
- **Network policy.** `flux-webhook-from-traefik` admits the webhook port (9292) of the notification-controller only from the Traefik pods. It keeps events (9090), metrics (8080) and health probes (9440) open, because a policy that selects a pod blocks every port it does not admit. The labels and ports come from the upstream Flux manifests. Confirm them in the `microsoft.flux` extension before you enable a cluster.
- **Admission policy.** `flux-webhook-receiver-types` admits a `Receiver` in a `product-*` namespace only with the type `generic-oidc` and the issuer `https://token.actions.githubusercontent.com` in every provider. The route exposes every `Receiver` in the cluster, and types such as `generic` and `acr` do no authentication. The policy checks create and update, not status updates or deletes. Before you enable a cluster, check that no product namespace has a `Receiver` of a different type, because the policy then blocks its updates.
- **No `secrets` layer.** The package takes `DEFAULT_GATEWAY_HOSTNAME` through `postBuild.substitute`. It is a host name, not a secret, and the DIS core clusters have no `dis-system-store`.
- The `edge` layer, with the edge route, the token check and the rate limits, comes in a later release.

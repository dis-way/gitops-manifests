# Flux Webhook Receiver

Routes reconcile requests from the DIS edge gateway to the Flux notification-controller in a DIS core cluster, for on-demand Flux reconcile ([RFC 0017](https://github.com/Altinn/altinn-platform/blob/main/rfcs/0017-on-demand-flux-reconcile.md)).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_GATEWAY_HOSTNAME` | - | Yes | `multitenancy`: DNS zone of the cluster's Traefik Gateway. The route answers on `flux-webhook.<DEFAULT_GATEWAY_HOSTNAME>` |
| `BASE_HOSTNAME` | - | Yes | `edge`: platform host name of the environment on the `eg` Gateway, for example `platform.at23.altinn.cloud`. The endpoint `https://<BASE_HOSTNAME>/flux-webhook` is also the audience of the token |
| `DIS_CORE_GATEWAY_HOSTNAME` | - | Yes | `edge`: `DEFAULT_GATEWAY_HOSTNAME` of the DIS core cluster that the edge cluster forwards to, for example `at23.dis-core.altinn.cloud` |
| `FLUX_WEBHOOK_REPOSITORY_LIMIT` | `10` | No | `edge`: requests each minute from one repository |
| `FLUX_WEBHOOK_ENVIRONMENT_LIMIT` | `60` | No | `edge`: requests each minute from all repositories together |

## Layers

| Path | Description |
|------|-------------|
| `multitenancy` | DIS core cluster: the route, the network policy and the admission policy below. The root `kustomization.yaml` builds this layer |
| `edge` | DIS edge cluster: the namespace `flux-webhook`, the route on the `eg` Gateway, the token check and the rate limits below |

## Notes

- **Enable.** The flag `enable_flux_webhook_receiver` of the `dis_aks_resources_multitenancy` module in `terraform-azurerm-dis-modules` deploys this package. The same flag selects the `multitenancy-flux-webhook` layer of `oci/traefik` (3.18.0 or later), which adds the listener that the route needs.
- **Route.** The `HTTPRoute` `flux-webhook-receiver` in `flux-system` attaches only to the `flux-webhook` listener of `traefik-gateway`. That listener's Service admits only the DIS edge outbound ranges on port 9443. The route matches only `POST` with the path prefix `/hook`, and it does not rewrite the path, because the notification-controller finds the `Receiver` by the exact path. The route assumes that `flux-system` is outside the Linkerd mesh, so it sets no `l5d-dst-override` header.
- **Network policy.** `flux-webhook-from-traefik` admits the webhook port (9292) of the notification-controller only from the Traefik pods. It keeps events (9090), metrics (8080) and health probes (9440) open, because a policy that selects a pod blocks every port it does not admit. The labels and ports come from the upstream Flux manifests. Confirm them in the `microsoft.flux` extension before you enable a cluster.
- **Admission policy.** `flux-webhook-receiver-types` admits a `Receiver` in a `product-*` namespace only with the type `generic-oidc` and the issuer `https://token.actions.githubusercontent.com` in every provider. The route exposes every `Receiver` in the cluster, and types such as `generic` and `acr` do no authentication. The policy checks create and update, not status updates or deletes. Before you enable a cluster, check that no product namespace has a `Receiver` of a different type, because the policy then blocks its updates.
- **Edge route.** The `HTTPRoute` `flux-webhook` attaches to the `https` listener of `eg` for `BASE_HOSTNAME`. It matches only `POST` with the path prefix `/flux-webhook/hook`, and rewrites the host to `flux-webhook.<DIS_CORE_GATEWAY_HOSTNAME>` and the prefix to `/hook`. A `Backend` and a `BackendTLSPolicy` send it to port 9443 of the DIS core cluster and verify the certificate with the system certificate authorities. Other requests to the platform host name keep their existing route. The annotation on the namespace lets `edge-route-guard` admit the path.
- **Token check.** `flux-webhook-github-oidc` reads a GitHub Actions OIDC token only from the `Authorization` header. It requires the audience `https://<BASE_HOSTNAME>/flux-webhook` and the `repository_owner_id` `5949420`, the Altinn organization. A missing, expired or invalid token gets `401`. A token with a different audience gets `403` from Envoy's JWT filter, and a token from a different organization gets `403` from the authorization rule. The token goes on to the `Receiver` unchanged, and the `Receiver` checks the repository and the branch.
- **Rate limits.** `flux-webhook-rate-limit` counts each repository separately, by the `repository_id` claim that the token check copies to `x-flux-webhook-repository-id`, so a client cannot choose its counter. It also counts all requests together. Requests that the token check rejects do not count. The policy merges with the Gateway policy `eg-local-ratelimit` (`mergeType: StrategicMerge`). The limiter fails open, and a Valkey restart sets the counters to zero, so the limits are not a hard bound.
- **No `secrets` layer.** The package takes its variables through `postBuild.substitute`. They are host names and limits, not secrets, and the DIS core clusters have no `dis-system-store`.

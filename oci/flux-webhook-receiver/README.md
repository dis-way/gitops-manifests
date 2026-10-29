# Flux Webhook Receiver

Routes reconcile requests from the DIS edge gateway to the Flux notification-controller in a DIS core cluster, for on-demand Flux reconcile ([RFC 0017](https://github.com/Altinn/altinn-platform/blob/main/rfcs/0017-on-demand-flux-reconcile.md)).

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `DEFAULT_GATEWAY_HOSTNAME` | - | Yes | `multitenancy`: DNS zone of the cluster's Traefik Gateway. The route answers on `flux-webhook.<DEFAULT_GATEWAY_HOSTNAME>` |
| `ENVIRONMENT` | - | Yes | `edge`: environment name (`at22`, `at23`, `yt01`, `tt02`, `prod`). The endpoint is `https://ops.<ENVIRONMENT>.dis.altinn.cloud/flux-webhook`, which is also the audience of the token |
| `DIS_CORE_GATEWAY_HOSTNAME` | - | Yes | `edge`: `DEFAULT_GATEWAY_HOSTNAME` of the DIS core cluster that the edge cluster forwards to, for example `at23.dis-core.altinn.cloud` |
| `FLUX_WEBHOOK_REPOSITORY_LIMIT` | `10` | No | `edge`: requests each minute from one repository |
| `FLUX_WEBHOOK_ENVIRONMENT_LIMIT` | `60` | No | `edge`: requests each minute from all repositories together |

## Layers

| Path | Description |
|------|-------------|
| `multitenancy` | DIS core cluster: the route and the admission policy below. The root `kustomization.yaml` builds this layer |
| `edge` | DIS edge cluster: the namespace `flux-webhook`, the route on the `dis` ListenerSet of the `eg` Gateway, the token check and the rate limits below |

## Notes

- **Enable.** The flag `enable_flux_webhook_receiver` of the `dis_aks_resources_multitenancy` module in `terraform-azurerm-dis-modules` deploys this package. The same flag selects the `multitenancy-flux-webhook` layer of `oci/traefik` (3.18.0 or later), which adds the listener that the route needs.
- **Route.** The `HTTPRoute` `flux-webhook-receiver` in `flux-system` attaches only to the `flux-webhook` listener of `traefik-gateway`. That listener's Service admits only the DIS edge outbound ranges on port 9443. The route matches only `POST` with the path prefix `/hook`, and it does not rewrite the path, because the notification-controller finds the `Receiver` by the exact path. The route assumes that `flux-system` is outside the Linkerd mesh, so it sets no `l5d-dst-override` header.
- **No network policy.** The `microsoft.flux` extension installs the NetworkPolicy `allow-webhooks` in `flux-system`, which admits all namespaces to the webhook port (9292) of the notification-controller. Kubernetes adds NetworkPolicies together, so a narrower policy cannot restrict that port, and an extra policy that selects the notification-controller can open its other ports. A workload in the cluster can therefore call a `Receiver` without the edge gateway and its rate limits. The `Receiver` still verifies the token.
- **Admission policy.** `flux-webhook-receiver-types` admits a `Receiver` in a `product-*` namespace only with the type `generic-oidc` and the issuer `https://token.actions.githubusercontent.com` in every provider. The route exposes every `Receiver` in the cluster, and types such as `generic` and `acr` do no authentication. The policy checks create and update, not status updates or deletes. Before you enable a cluster, check that no product namespace has a `Receiver` of a different type, because the policy then blocks its updates.
- **Edge route.** The `HTTPRoute` `flux-webhook` attaches to the `https` listener of the `dis` ListenerSet (`oci/envoy-gateway` 4.0.0 or later) for `ops.<ENVIRONMENT>.dis.altinn.cloud`. The wildcard certificate and DNS record of the ListenerSet cover this host name. The route matches only `POST` with the path prefix `/flux-webhook/hook`, and rewrites the host to `flux-webhook.<DIS_CORE_GATEWAY_HOSTNAME>` and the prefix to `/hook`. A `Backend` and a `BackendTLSPolicy` send it to port 9443 of the DIS core cluster and verify the certificate with the system certificate authorities. The annotation on the namespace lets `edge-route-guard` admit the path.
- **Token check.** `flux-webhook-github-oidc` reads a GitHub Actions OIDC token only from the `Authorization` header. It requires the audience `https://ops.<ENVIRONMENT>.dis.altinn.cloud/flux-webhook` and the `repository_owner_id` `5949420`, the Altinn organization. A missing, expired or invalid token gets `401`. A token with a different audience gets `403` from Envoy's JWT filter, and a token from a different organization gets `403` from the authorization rule. The token goes on to the `Receiver` unchanged, and the `Receiver` checks the repository and the branch.
- **Rate limits.** `flux-webhook-rate-limit` counts each repository separately, by the `repository_id` claim that the token check copies to `x-flux-webhook-repository-id`, so a client cannot choose its counter. It also counts all requests together. Requests that the token check rejects do not count. The policy merges with the Gateway policy `eg-local-ratelimit` (`mergeType: StrategicMerge`). The limiter fails open, and a Valkey restart sets the counters to zero, so the limits are not a hard bound.
- **No `secrets` layer.** The package takes its variables through `postBuild.substitute`. They are host names and limits, not secrets, and the DIS core clusters have no `dis-system-store`.

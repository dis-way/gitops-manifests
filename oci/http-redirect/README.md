# HTTP Redirect

Redirects HTTPS traffic for one host (and optional path prefix) to another host with a Gateway API `HTTPRoute`, with an optional dedicated `Gateway` and cert-manager `Certificate`.

Deploy one Flux `Kustomization` per redirect. `REDIRECT_NAME` names every resource, so several redirects can share a namespace.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `REDIRECT_NAME` | — | Yes | Name of the `Gateway`, `HTTPRoute` and `Certificate` |
| `REDIRECT_NAMESPACE` | `traefik` | No | Namespace for all resources |
| `REDIRECT_FROM_FQDN` | — | Yes | Source host, no protocol (e.g. `grafana.altinn.cloud`) |
| `REDIRECT_TO_FQDN` | — | Yes | Target host, no protocol (e.g. `altinn-grafana-xyz.eno.grafana.azure.com`) |
| `REDIRECT_FROM_PATH_PREFIX` | `/` | No | Only redirect requests under this path prefix (e.g. `/monitor`) |
| `REDIRECT_TO_PATH_PREFIX` | `/` | No | Replaces the matched prefix; the rest of the path and the query string are kept |
| `REDIRECT_STATUS_CODE` | `301` | No | `301` or `302` (the codes with Core support in Gateway API) |
| `REDIRECT_GATEWAY_PORT` | `8443` | No | Traefik entrypoint port for the dedicated `Gateway` listener (`8444` for the private `https-internal` entrypoint on `adminservices`) |
| `REDIRECT_TLS_SECRET_NAME` | `<REDIRECT_NAME>-tls` | `reference-grant` only | TLS secret used by the `base` `Gateway` and written by `post-deploy`; set to an existing secret to reuse its certificate |
| `REDIRECT_TLS_SECRET_NAMESPACE` | `REDIRECT_NAMESPACE` | `reference-grant` only | Namespace of the TLS secret; anything other than `REDIRECT_NAMESPACE` needs the `reference-grant` layer |
| `REDIRECT_CLUSTER_ISSUER` | `letsencrypt-production` | No | cert-manager `ClusterIssuer` for the `post-deploy` `Certificate`, e.g. `zerossl-dis-tls-cert` or `digicert-dis-tls-cert` |
| `REDIRECT_PARENT_GATEWAY_NAME` | — | `shared-gateway` only | Existing `Gateway` to attach the `HTTPRoute` to |
| `REDIRECT_PARENT_GATEWAY_NAMESPACE` | `traefik` | No | Namespace of the existing `Gateway` (`shared-gateway` only) |
| `REDIRECT_PARENT_GATEWAY_SECTION` | `https` | No | Listener name on the existing `Gateway` (`shared-gateway` only) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Dedicated `Gateway` (class `traefik`, HTTPS listener for `REDIRECT_FROM_FQDN`) and the redirecting `HTTPRoute` |
| `shared-gateway` | `HTTPRoute` only, attached to an existing `Gateway` that already terminates TLS for the source host — no `post-deploy` needed |
| `post-deploy` | cert-manager `Certificate` for `REDIRECT_FROM_FQDN`, written to `REDIRECT_TLS_SECRET_NAME` and used by the `base` `Gateway` |
| `reference-grant` | `ReferenceGrant` in `REDIRECT_TLS_SECRET_NAMESPACE` letting the `base` `Gateway` use an existing secret from another namespace |

### Reusing an existing certificate

To use a certificate that already exists, e.g. the cluster wildcard `ssl-cert` (`*.apps.altinn.no`) in `traefik`, deploy `base` with `REDIRECT_TLS_SECRET_NAME` (and `REDIRECT_TLS_SECRET_NAMESPACE` if it differs from `REDIRECT_NAMESPACE`) and skip `post-deploy`. Add `reference-grant` only when the secret lives in another namespace. The certificate must cover `REDIRECT_FROM_FQDN` — a wildcard matches a single label only.

If a `Gateway` listener already serves the host, `shared-gateway` is simpler: it reuses that listener and its certificate.

Requires the Traefik Gateway API provider (`apps`, `adminservices` or `multitenancy` variants of `oci/traefik`). Plain HTTP is already redirected to HTTPS at the Traefik `http` entrypoint, so only an HTTPS listener is created.

Deploy `post-deploy` from a separate Flux `Kustomization` with `wait: false` and `dependsOn` the main one, so cert-manager can issue the certificate asynchronously without blocking health checks. Until the certificate is issued, Traefik serves its default certificate for the host.

A `shared-gateway` route only attaches if the parent listener's `allowedRoutes` admits `REDIRECT_NAMESPACE` and its hostname covers `REDIRECT_FROM_FQDN`.

## Behavior

`https://<REDIRECT_FROM_FQDN><REDIRECT_FROM_PATH_PREFIX><rest>?<query>` is redirected to `https://<REDIRECT_TO_FQDN><REDIRECT_TO_PATH_PREFIX><rest>?<query>`. For example, with `REDIRECT_FROM_PATH_PREFIX=/monitor` and the default target prefix, `/monitor/d/abc?orgId=1` becomes `/d/abc?orgId=1`.

Check after deploying:

```
curl -I https://<REDIRECT_FROM_FQDN>/some/path?x=1
```

Expect `301 Moved Permanently` with `Location: https://<REDIRECT_TO_FQDN>/some/path?x=1`.

## DNS prerequisite for the certificate

All issuers solve DNS-01, so the source FQDN's zone needs an `_acme-challenge` CNAME before `post-deploy` is deployed — unless the FQDN lives inside the zone the issuer writes to.

- **`letsencrypt-production`** (from `certm-lets-encrypt-dns-issuer`) writes to the cluster's delegated child zone (`AZURE_DNS_ZONE_NAME`, e.g. `test.admin.altinn.cloud`) and leaves `cnameStrategy` unset. For a host outside that zone it writes the full name inside the child zone, so delegate with:

  ```
  _acme-challenge.<REDIRECT_FROM_FQDN>  CNAME  _acme-challenge.<REDIRECT_FROM_FQDN>.<AZURE_DNS_ZONE_NAME>
  ```

- **`zerossl-dis-tls-cert`** and **`digicert-dis-tls-cert`** (from `dis-tls-cert`) solve against the `acme.altinn.cloud` zone with `cnameStrategy: Follow`, so point the challenge name into that zone:

  ```
  _acme-challenge.<REDIRECT_FROM_FQDN>  CNAME  <any-unique-name>.acme.altinn.cloud
  ```

  These issuers only exist on clusters where `dis-tls-cert` is deployed.

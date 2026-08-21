# Grafana FQDN Redirect

Redirect all traffic from a legacy Grafana host to an Azure Managed Grafana host, preserving path and query.

## Variables

- `REDIRECT_GRAFANA_FROM_FQDN`: Source (legacy) Grafana FQDN (no protocol), e.g. `grafana.altinn.cloud`
- `REDIRECT_GRAFANA_TO_FQDN`: Target Azure Managed Grafana FQDN (no protocol), e.g. `altinn-grafana-xyz.eno.grafana.azure.com`

## Behavior

Any HTTPS request to `https://${REDIRECT_GRAFANA_FROM_FQDN}` including arbitrary path and query is permanently (HTTP 301) redirected to:
`https://${REDIRECT_GRAFANA_TO_FQDN}<same path><same query>`

Fragments (`#...`) are never sent to the server and are not part of the redirect (standard HTTP behavior).

## Resources

- Traefik Middleware: `redirect-grafana-fqdn-to-azure-grafana`
- Traefik IngressRoute: `redirect-grafana-fqdn-to-azure-grafana` (entryPoint: `https`, service: `noop@internal`, TLS secret: `redirect-grafana-fqdn-to-azure-grafana-tls`)
- cert-manager Certificate (`post-deploy`): `redirect-grafana-fqdn-to-azure-grafana-tls` in namespace `traefik`, issued by the `letsencrypt-production` ClusterIssuer for `${REDIRECT_GRAFANA_FROM_FQDN}`

## Layers

| Path | Description |
|------|-------------|
| `.` | Traefik Middleware and IngressRoute performing the redirect |
| `post-deploy` | cert-manager Certificate for the source FQDN |

Deploy `post-deploy` from a separate Flux `Kustomization` with `wait: false` and `dependsOn` the main one, so cert-manager can issue the certificate asynchronously without blocking health checks. Until the certificate is issued, Traefik serves the default certificate from the `tlsStore` for this host.

### DNS prerequisite

The `letsencrypt-production` ClusterIssuer comes from the `certm-lets-encrypt-dns-issuer` config, which solves DNS-01 against a single Azure DNS zone (`AZURE_DNS_ZONE_NAME` — the cluster's delegated child zone, e.g. `test.admin.altinn.cloud`) and leaves `cnameStrategy` unset.

When `${REDIRECT_GRAFANA_FROM_FQDN}` lives outside that zone, cert-manager cannot trim the zone suffix off `_acme-challenge.${REDIRECT_GRAFANA_FROM_FQDN}`, so it writes the challenge TXT record at the full name *inside* the child zone. Delegate to it with a CNAME in the source FQDN's own zone before deploying `post-deploy`:

```
_acme-challenge.<REDIRECT_GRAFANA_FROM_FQDN>  CNAME  _acme-challenge.<REDIRECT_GRAFANA_FROM_FQDN>.<AZURE_DNS_ZONE_NAME>
```

For example, with `REDIRECT_GRAFANA_FROM_FQDN=grafana.altinn.cloud` and a `test.admin.altinn.cloud` child zone, add this to the `altinn.cloud` zone:

```
_acme-challenge.grafana  CNAME  _acme-challenge.grafana.altinn.cloud.test.admin.altinn.cloud
```

This mirrors how `headscale.altinn.cloud` and `headplane.altinn.cloud` are issued from the `admin-prod` cluster.

## Test

Example:
```
curl -I https://grafana.altinn.cloud/d/abc123/my-dashboard?orgId=1
```
Expect: `HTTP/1.1 301 Moved Permanently` with `Location: https://<target>/d/abc123/my-dashboard?orgId=1`.

## Notes

- Do not include protocol or trailing slash in FQDN variables.
- Change to a temporary redirect (302) by setting `permanent: false` in `middleware.yaml` if doing a staged rollout.
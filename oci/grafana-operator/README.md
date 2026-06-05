# Grafana Operator

Deploys the Grafana Operator via Helm and connects it to an external Azure Managed Grafana instance.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `GRAFANA_ADMIN_APIKEY` | — | Yes | Admin API key for the external Grafana instance |
| `EXTERNAL_GRAFANA_URL` | — | Yes | Full URL of the external Azure Managed Grafana instance |
| `K8S_DNS_NAME` | — | Yes | Cluster DNS hostname used in the `/monitor` redirect IngressRoute |
| `REDIRECT_GRAFANA_FROM_FQDN` | — | Yes | Legacy Grafana FQDN to redirect from (no protocol, `fqdn-to-azure-grafana` only) |
| `REDIRECT_GRAFANA_TO_FQDN` | — | Yes | Target Azure Managed Grafana FQDN to redirect to (no protocol, `fqdn-to-azure-grafana` only) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, HelmRepository, HelmRelease (grafana-operator), and `grafana-admin-apikey` Secret |
| `adminservices` | Overlay for the admin services cluster; references `base` |
| `adminservices/post-deploy` | External Grafana CR and Traefik `/monitor` redirect; depends on `adminservices` |
| `dis` | Overlay for the DIS cluster; references `base` |
| `post-deploy` | `Grafana` CR connecting to the external Azure Managed Grafana instance |
| `grafana-redirect` | Traefik `IngressRoute` and `Middleware` redirecting `/monitor` traffic to Azure Grafana |
| `grafana-manifests/base` | `GrafanaDashboard` CRs: blackbox exporter, public IP, Traefik, FluxCD, and Linkerd dashboards |
| `grafana-manifests/apps` | Overlay adding the Altinn pod console error log dashboard |
| `fqdn-to-azure-grafana` | Traefik redirect from a legacy Grafana FQDN to Azure Managed Grafana (HTTP 301, path-preserving) |
.

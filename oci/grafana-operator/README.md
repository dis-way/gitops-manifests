# Grafana Operator

Deploys the Grafana Operator via Helm and connects it to an external Azure Managed Grafana instance.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `GRAFANA_ADMIN_APIKEY` | — | Yes | Admin API key for the external Grafana instance |
| `EXTERNAL_GRAFANA_URL` | — | Yes | Full URL of the external Azure Managed Grafana instance (`post-deploy` only) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, HelmRepository, HelmRelease (grafana-operator), and `grafana-admin-apikey` Secret |
| `post-deploy` | `Grafana` CR `external-grafana` connecting to the external Azure Managed Grafana instance; depends on `base` |
| `adminservices` | Overlay for the admin services cluster; references `base` |

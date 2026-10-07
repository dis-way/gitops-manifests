# Grafana Dashboards

Deploys the platform `GrafanaDashboard` and `GrafanaFolder` CRs from `Altinn/altinn-dashboards-grafana` (`main`) into a cluster's own Grafana via grafana-operator; requires `oci/grafana-operator` and its `external-grafana` instance.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| — | — | — | No variables |

## Layers

| Path | Description |
|------|-------------|
| `base` | `Altinn`, `Fluxcd` and `Linkerd` folders; blackbox exporter, public IP, Traefik, FluxCD and Linkerd dashboards |
| `apps` | `base` plus the Altinn pod console error log dashboard, for apps clusters |

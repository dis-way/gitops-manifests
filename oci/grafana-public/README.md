# Grafana Public

Self-hosted Grafana OSS, managed by grafana-operator, for dashboards shared publicly with customers at `dashboards.altinn.cloud`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `GRAFANA_PUBLIC_WI_CLIENT_ID` | - | Yes | Client ID of the user-assigned identity the Azure datasources authenticate as (workload identity) |
| `GRAFANA_PUBLIC_ENTRA_CLIENT_ID` | - | Yes | Microsoft Entra app registration client ID for sign-in |
| `GRAFANA_PUBLIC_ENTRA_CLIENT_SECRET` | - | Yes | Microsoft Entra app registration client secret — source from a secret store, not plain substitution |
| `GRAFANA_PUBLIC_PROMETHEUS_URL` | - | Yes | Query endpoint of the Azure Monitor workspace behind the public dashboards |

## Layers

| Path | Description |
|------|-------------|
| `.` | Core resources: namespace, ServiceAccount, Entra secret, `Grafana` CR, Prometheus datasource, gateway and HTTPRoute |
| `post-deploy` | cert-manager Certificate for Let's Encrypt TLS |
| `policies` | Included by the root kustomization. Default-deny NetworkPolicies (enforced by Cilium) allowing only Traefik, grafana-operator, Entra ID, the Azure Monitor query endpoint and metrics scraping (ama-metrics, otel collector) |

## Requirements

- grafana-operator >= 5.25.0 in the `grafana` namespace (`oci/grafana-operator`). `GrafanaDashboard.spec.publicSharing` was added in 5.25.0.
- Dashboards target this instance with `instanceSelector: {matchLabels: {dashboards: public-grafana}}`. Apply them in the `grafana-public` namespace, or set `allowCrossNamespaceImport: true`.

## Storage

Grafana runs on the operator's default `emptyDir` SQLite database with one replica. Everything that matters is declared as CRs and recreated by the operator after a restart. Set `spec.publicSharing.accessToken` on every public dashboard: without a pinned token, Grafana generates a new one when the dashboard is recreated and customer links break. Sessions and UI edits are lost on restart.

## Identity

The datasource identity runs every query from a public dashboard. Use a dedicated user-assigned identity with `Monitoring Data Reader` only on the Azure Monitor workspace(s) the public dashboards read. Its federated identity credential subject is `system:serviceaccount:grafana-public:grafana-public`.

Sign-in roles come from Entra app roles on the app registration (`Viewer`, `Editor`, `Admin`, `GrafanaAdmin`). `role_attribute_strict` rejects users without one. The redirect URI is `https://dashboards.altinn.cloud/login/azuread`.

## Prerequisites

### DNS

Two records are required in the `altinn.cloud` zone:

1. **Service record** — points the hostname at the public Traefik load balancer (`websecure` entrypoint, see `oci/traefik`).
2. **ACME delegation** — delegates the DNS-01 challenge to the Azure DNS zone managed by cert-manager:

```text
_acme-challenge.dashboards.altinn.cloud  CNAME  _acme-challenge.dashboards.altinn.cloud.prod.admin.altinn.cloud
```

The ACME delegation must be in place before deploying `post-deploy/`.

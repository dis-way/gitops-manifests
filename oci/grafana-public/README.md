# Grafana Public

Self-hosted Grafana OSS, managed by grafana-operator, for dashboards shared publicly with customers at `dashboards.altinn.cloud`.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `GRAFANA_PUBLIC_WI_CLIENT_ID` | - | Yes | Client ID of the user-assigned identity the Azure datasources authenticate as (workload identity) |
| `GRAFANA_PUBLIC_ENTRA_CLIENT_ID` | - | Yes | Microsoft Entra app registration client ID for sign-in |
| `GRAFANA_PUBLIC_ENTRA_CLIENT_SECRET` | - | Yes | Microsoft Entra app registration client secret |
| `GRAFANA_PUBLIC_PROMETHEUS_URL` | - | Yes | Query endpoint of the Azure Monitor workspace behind the public dashboards |

All four come from the dis-system Key Vault. The `secrets` layer syncs them into the `grafana-public-vars` Secret in `flux-system`, which the Flux Kustomization for `.` reads with `postBuild.substituteFrom`.

| Key Vault secret | Variable |
|------------------|----------|
| `grafana-public-wi-client-id` | `GRAFANA_PUBLIC_WI_CLIENT_ID` |
| `grafana-public-entra-client-id` | `GRAFANA_PUBLIC_ENTRA_CLIENT_ID` |
| `grafana-public-entra-client-secret` | `GRAFANA_PUBLIC_ENTRA_CLIENT_SECRET` |
| `grafana-public-prometheus-url` | `GRAFANA_PUBLIC_PROMETHEUS_URL` |

## Layers

| Path | Description |
|------|-------------|
| `.` | Core resources: namespace, ServiceAccount, Entra secret, `Grafana` CR, Prometheus datasource, gateway and HTTPRoute |
| `secrets` | `ExternalSecret` in `flux-system` reading the input variables from `dis-system-store` (`oci/external-secrets-operator` `adminservices/post-deploy`). Apply before `.`, which depends on it for `substituteFrom` |
| `post-deploy` | cert-manager Certificate for Let's Encrypt TLS |
| `policies` | Included by the root kustomization. Default-deny NetworkPolicies (enforced by Cilium) allowing only Traefik, grafana-operator, Entra ID, the Azure Monitor query endpoint and metrics scraping (ama-metrics, otel collector) |

## Requirements

- grafana-operator >= 5.25.0 in the `grafana` namespace (`oci/grafana-operator`). `GrafanaDashboard.spec.publicSharing` was added in 5.25.0.
- Dashboards target this instance with `instanceSelector: {matchLabels: {dashboards: public-grafana}}`. Apply them in the `grafana-public` namespace, or set `allowCrossNamespaceImport: true`.

## Storage

Grafana runs on the operator's default `emptyDir` SQLite database with one replica. Everything that matters is declared as CRs and recreated by the operator after a restart. Set `spec.publicSharing.accessToken` on every public dashboard: without a pinned token, Grafana generates a new one when the dashboard is recreated and customer links break. Grafana stores the token without dashes, so the public URL is `/public-dashboards/<accessToken without dashes>` (also in the CR's `status.publicSharingPath`). Sessions and UI edits are lost on restart.

## Plugins

Grafana 13 removed Azure authentication from the core Prometheus datasource and does not bundle `grafana-azureprometheus-datasource`, which the datasource here uses. `plugins.preinstall_sync` in `grafana.yaml` installs a pinned version from grafana.com at every start, so the pod needs outbound access to grafana.com when it starts. Renovate tracks the version through the plugin's [GitHub releases](https://github.com/grafana/azure-prometheus-datasource/releases), which are tagged after the grafana.com publish. Renovate does not check the plugin's Grafana compatibility; verify it on grafana.com when bumping either.

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

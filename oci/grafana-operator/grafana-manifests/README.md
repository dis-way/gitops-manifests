# Grafana Manifests

This directory wires the cluster's Grafana content (folders, dashboards, and
product alerts) to an external Flux OCI artifact. It no longer holds the CRs
themselves — they are delivered by the `altinn-dashboards-grafana` repository.

## Structure

```
grafana-manifests/
├── README.md
├── base/
│   ├── kustomization.yaml      # references the two Flux objects below
│   ├── oci-repository.yaml     # OCIRepository: grafana-content
│   └── flux-kustomize.yaml     # Kustomization: grafana-content
└── apps/
    └── kustomization.yaml      # thin passthrough to ../base
```

## Manifest Sources

Grafana folders, dashboards, and product alerts are delivered by the external
[`altinn-dashboards-grafana`](https://github.com/Altinn/altinn-dashboards-grafana)
Flux OCI artifact, published to `oci://altinncr.azurecr.io/monitoring/grafana`
and pinned to `tag: release`.

This package applies that artifact via two Flux objects in `base/`:

- **`oci-repository.yaml`** — an `OCIRepository` named `grafana-content` that
  pulls `oci://altinncr.azurecr.io/monitoring/grafana:release` (Azure provider).
- **`flux-kustomize.yaml`** — a `Kustomization` named `grafana-content` that
  reconciles the artifact's repo-root kustomization (dashboards as
  self-contained `configMapRef` CRs, the platform folders, and all product
  alerts) into the `grafana` namespace with `prune: true`.

Dashboards, folders, and alerts are added or changed in the
`altinn-dashboards-grafana` repository — not here. Promote `main` → `release`
there to roll out new content.

## Usage

### Deploy Base Only
Point Flux Kustomization to:
```
oci://your-registry/grafana-operator/grafana-manifests/base
```

### Deploy Apps (includes Base)
Point Flux Kustomization to:
```
oci://your-registry/grafana-operator/grafana-manifests/apps
```

Both targets render the same two `grafana-content` Flux objects; `apps` is a
thin passthrough to `base`.

## Dependencies

These manifests depend on:
- Grafana Operator being deployed
- External Grafana instance configured via `EXTERNAL_GRAFANA_URL`
- Proper RBAC permissions for the Grafana Operator
- The Flux source-controller identity having `AcrPull` on
  `altinncr.azurecr.io` so the `grafana-content` `OCIRepository` can pull the
  artifact

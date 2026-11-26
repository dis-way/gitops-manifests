---
name: envoy-gateway
description: Checklist for changing or upgrading Envoy Gateway in this repo. Use before editing anything under oci/envoy-gateway or oci/envoy-gateway-crds, bumping the gateway-helm chart or the Envoy proxy image, or reviewing Envoy Gateway / Envoy release notes for impact.
---

# Envoy Gateway changes

## Envoy proxy image (pull-through)

- `base/helmrelease.yaml` must keep `global.images.envoyProxy.image: docker.io/envoyproxy/envoy`, **untagged**. The chart's `eg.envoyProxy.image` helper then adds the chart's Envoy version and applies `global.imageRegistry` (`altinncr.azurecr.io/docker.io`). If the key is removed, Envoy Gateway uses its built-in image straight from docker.io.
- To pin a patched Envoy temporarily, add only a tag (`docker.io/envoyproxy/envoy:distroless-vX.Y.Z`). Never write the `altinncr` path into the value, because the helper adds the registry itself. To unpin later, remove only the tag.
- The image reaches the data plane only because the `eg` EnvoyProxy (`default-gateway/envoy-proxy.yaml`) sets `mergeType: StrategicMerge`. Keep it.
- Verify the rendered image before merging a chart bump:
  ```sh
  helm template oci://docker.io/envoyproxy/gateway-helm --version <ver> \
    --set global.imageRegistry=altinncr.azurecr.io/docker.io \
    --set global.images.envoyProxy.image=docker.io/envoyproxy/envoy \
    | grep -o '[a-z.]*/[a-z/.]*envoyproxy/envoy:[^"]*' | sort -u
  ```
  Expect `altinncr.azurecr.io/docker.io/envoyproxy/envoy:distroless-...`. Also check the Envoy patch release notes for that version. Distroless images have shipped stale `ca-certificates` bundles before (1.39.5, 1.40.0-1.40.1).

## Upgrading the chart

1. Read the Envoy Gateway release notes for every version you skip (https://gateway.envoyproxy.io/news/releases/notes/). Also read the Envoy version history for the bundled Envoy minor (https://www.envoyproxy.io/docs/envoy/latest/version_history/version_history). The pages are long, and fetches truncate them, so read them in chunks.
2. Check the compatibility matrix (https://gateway.envoyproxy.io/news/releases/matrix/). The Gateway API version must match the `oci/gateway-api` tag, and the Kubernetes range must cover every edge cluster.
3. Check what the breaking changes hit:
   - This repo: `oci/envoy-gateway/**` and `oci/flux-webhook-receiver/edge` (JWT SecurityPolicy, Backend, global rate limit).
   - Team manifests deployed to the edge cluster: `Altinn/correspondence-manifests` and `Altinn/dialogporten-manifests`, under `flux/edge-syncroot`.
   - Dashboards: `Altinn/altinn-dashboards-grafana`, `dashboards/dis-edge` (control-plane metrics such as `watchable_*`, `xds_*`, `status_update_*`).
4. CRDs and chart go in **separate PRs**. Bump `ENVOY_GATEWAY_VERSION` in `oci/envoy-gateway-crds/scripts/update-crds.sh`, run the script, then run it again with `--check`. The sandbox cannot reach github.com, so the user runs it. The chart installs with `crds: Skip`, so `envoy-gateway-crds` must reach each ring in `oci/releaseconfig.json` before `envoy-gateway`.
5. Commit type: `feat(envoy-gateway)` or `deps(...)`. Use `!` only when the package's variables or layers change for consumers, not because upstream lists breaking changes.

## Other gotchas

- Any `config.envoyGateway` change takes effect only after the controller restarts (see the package README).
- Deprecated fields to move off before Envoy Gateway v1.11: `host`/`port` on EnvoyProxy telemetry sinks (use `backendRefs`), singular `targetRef`/`backendRef`, `enableProxyProtocol`, `preserveXRequestID`, `compression`.
- Metric names in Azure Monitor Workspace have no `envoy_` prefix, and counters get `_total`.

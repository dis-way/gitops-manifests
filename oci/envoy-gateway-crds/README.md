# Envoy Gateway CRDs

Deploys the Envoy Gateway `gateway.envoyproxy.io` CustomResourceDefinitions, vendored from the upstream release asset. Gateway API CRDs are not included here — they are owned by the `gateway-api` package.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| - | - | No | No configurable variables for this package |

## Layers

| Path | Description |
|------|-------------|
| `base` | The 8 `gateway.envoyproxy.io` CRDs, applied directly by Flux. No HelmRelease and no namespace needed — CRDs are cluster-scoped |
| `multitenancy` | Passthrough overlay, kept so consumers referencing this path keep working |

## Upgrading

`base/envoy-gateway-crds.yaml` is generated — do not edit it by hand. The version is pinned in `scripts/update-crds.sh` and maintained by Renovate, which groups it with the chart version in the `envoy-gateway` package so the CRDs and the control plane always move together. `.github/workflows/refresh-envoy-gateway-crds.yml` re-downloads the matching asset on the Renovate PR; to refresh or verify manually:

```sh
./oci/envoy-gateway-crds/scripts/update-crds.sh           # re-vendor the pinned version
./oci/envoy-gateway-crds/scripts/update-crds.sh --check   # verify against upstream
```

### Integrity

- **Every download is verified against GitHub's recorded digest.** The `digest` field on the release asset is read from `api.github.com`, while the bytes come from `release-assets.githubusercontent.com` — two different hosts, so this catches a corrupted, truncated or tampered download without the expected value having to be computed locally. The check **fails closed**: if the digest cannot be read, the script refuses rather than skipping. Set `GH_TOKEN` if you hit the unauthenticated API rate limit.
- **The verified digest is recorded in the generated file's header**, so it appears in the pull request diff and can be confirmed independently against the API.
- **The bytes are committed to git.** What reaches a cluster comes from a reviewed commit and a released OCI artifact, not a download at apply time.
- **`--check` re-verifies the committed bytes against upstream.** It runs on every pull request touching this package except the Renovate refresh, which re-vendors the manifest from upstream instead — so one path or the other verifies it on every pull request. `--check` is what catches a hand-edit of the generated file, and an upstream asset that changed after it was vendored — release assets are mutable, unlike git tags.
- **The script bounds the shape of the asset** before writing: minimum size, no Helm template markers, exactly 8 CRDs, and no top-level object that is not one of those CRDs, so nothing can ride along inside the file.

What none of this covers: a malicious *upstream release* would carry a matching digest. That is upstream trust, and it is unchanged from installing the chart.

A SHA-256 pinned next to the version would add nothing on top: Renovate cannot compute an asset digest when it bumps the version, so the value would have to be written by the same automated step that did the download. Verifying against the API digest, plus the committed bytes, is both stronger and self-maintaining.

Helm is deliberately not used: the `gateway-crds-helm` chart embeds ~5 MB of CRD templates in the Helm release object, which exceeds the 1 MB Kubernetes Secret limit regardless of which CRDs are enabled via values.

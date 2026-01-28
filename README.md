# gitops-manifests

Repository for GitOps manifests to deploy DIS resources.

## OCI artifacts (`oci/`)

Each folder under `oci/<name>/` is treated as a **Flux OCI artifact** (built from the folder contents and pushed/tagged by GitHub workflows).

## Adding a new OCI package (`oci/<name>`)

- **1) Create the package folder**
  - **Create** `oci/<name>/`
  - **Add** `oci/<name>/kustomization.yaml` at the package root.
  - **Ensure** it is a valid Kustomize package (i.e. `kustomize build oci/<name>` produces valid Kubernetes YAML and includes whatever resources you intend to deploy).

- **2) Register the package with Release Please**
  - **Update** `release-please-config.json`
    - Add a new entry under `packages`:
      - key: `oci/<name>`
      - `release-type`: `"simple"`
      - `component`: `"oci-<name>"`
  - **Update** `.release-please-manifest.json`
    - Add an initial version entry:
      - key: `oci/<name>`
      - value: `"1.0.0"` (or whatever initial version you want to start from)

- **3) Add the package changelog**
  - **Create** `oci/<name>/CHANGELOG.md` (Release Please updates it on release)

- **4) Register where it should deploy**
  - **Update** `oci/releaseconfig.json`
    - Add an entry keyed by the **release name** (folder name, **without** the `oci/` prefix), e.g.:
      - key: `<name>`
      - values: environment/ring versions (currently: `at_ring1`, `at_ring2`, `tt_ring1`, `tt_ring2`, `prod_ring1`, `prod_ring2`)

# gitops-manifests

Repository for GitOps manifests to deploy DIS resources.

## OCI artifacts (`oci/`)

Each folder under `oci/<name>/` is treated as a **Flux OCI artifact** (built from the folder contents and pushed/tagged by GitHub workflows).

## Rings and clusters (`clusters_in_rings.json`)

`clusters_in_rings.json` lists the clusters (kube context names) that follow each ring. Promoting a package to a ring in `oci/releaseconfig.json` can update any cluster in that ring that deploys the package.

A cluster's ring is set in one of two places:

- Most clusters: `flux_release_tag` in the cluster's Terraform repo, which becomes the tag on its AKS Flux configurations.
- dis-edge clusters: the manifests in `dis-way/core` under `flux/clusters/<cluster>/`. These clusters use flux-operator ResourceSets, not AKS Flux configurations.

When a ring changes, update this file and the `verified` date. `untracked` lists AKS clusters that pull no `manifests/infra` artifacts.

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

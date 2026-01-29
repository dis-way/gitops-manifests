# Repository Guidelines

This repository contains GitOps manifests for deploying DIS resources with Flux. Each `oci/<name>/` folder is built as a Flux OCI artifact by GitHub workflows and versioned via Release Please.

## Project Structure & Module Organization

- `oci/<name>/`: One package per deployable unit; must include a root `kustomization.yaml`. Many packages use `base/`, `apps/`, or `post-deploy/` subfolders for overlays and follow-on resources.
- `oci/releaseconfig.json`: Maps package release names (folder name without `oci/`) to ring/environment versions.
- `.github/workflows/`: Automation for building OCI artifacts and running Release Please.
- `release-please-config.json` and `.release-please-manifest.json`: Package registration and version tracking.

## Build, Test, and Development Commands

- Validate manifests for a package:
  - `kustomize build oci/<name>`
- Apply or test in a cluster (package-specific; see per-package docs such as `oci/altinn-uptime/DEPLOY.md`):
  - `kubectl apply -k <kustomize-path>`
- Do not run `kubectl` commands without explicit confirmation.

## Coding Style & Naming Conventions

- Use 2-space YAML indentation and follow existing file naming (kebab-case, e.g., `helmrelease.yaml`, `kustomization.yaml`).
- Keep resource names, labels, and namespaces consistent with existing patterns in the same package.
- Prefer Flux CRDs (`HelmRepository`, `HelmRelease`, `Kustomization`) where already used.

## Testing Guidelines

- There is no centralized test suite. Treat `kustomize build` as the primary validation step.
- For packages with custom instructions, follow the package README/DEPLOY docs before merging.

## Commit & Pull Request Guidelines

- Commit messages follow Conventional Commits. Recent examples: `feat!: ...`, `docs: ...`, `chore(main): ...`, `release: ...`.
- PRs should include a concise summary, list affected `oci/<name>` packages, and mention any changes to `oci/releaseconfig.json` or Release Please config files.

## Adding or Updating OCI Packages

- Add `oci/<name>/kustomization.yaml` and ensure `kustomize build oci/<name>` renders valid Kubernetes YAML.
- Register the package in `release-please-config.json` and `.release-please-manifest.json`.
- Add or update the package entry in `oci/releaseconfig.json` to control ring/environment versions.

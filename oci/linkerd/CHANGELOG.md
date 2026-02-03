# Changelog

## [2.5.1](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.5.0...oci-linkerd-v2.5.1) (2026-02-03)


### Bug Fixes

* **linkerd:** use gRPC for proxyProtocol ([#248](https://github.com/dis-way/gitops-manifests/issues/248)) ([bceb94c](https://github.com/dis-way/gitops-manifests/commit/bceb94c5471ebea33d0e962e64dfd4f52de19514))

## [2.5.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.4.0...oci-linkerd-v2.5.0) (2026-02-03)


### Features

* **linkerd:** Add node CIDR auth and admin svcs ([#215](https://github.com/dis-way/gitops-manifests/issues/215)) ([11a01c0](https://github.com/dis-way/gitops-manifests/commit/11a01c0874338969524ce94bf39d016eb63d1e41))

## [2.4.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.3.0...oci-linkerd-v2.4.0) (2026-02-02)


### Features

* **linkerd:** Add control-plane policies ([#180](https://github.com/dis-way/gitops-manifests/issues/180)) ([2d14517](https://github.com/dis-way/gitops-manifests/commit/2d14517e24b28211f20c6c2607d86f0cac0bec6e))

## [2.3.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.2.0...oci-linkerd-v2.3.0) (2026-01-30)


### Features

* **linkerd:** grant cluster-admin to flux-applier ([#154](https://github.com/dis-way/gitops-manifests/issues/154)) ([54c9f1e](https://github.com/dis-way/gitops-manifests/commit/54c9f1e38ed5a95c8210642c9a68033d0e37210c))

## [2.2.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.1.0...oci-linkerd-v2.2.0) (2026-01-30)


### Features

* Add Linkerd HelmRepo and simplify kustomize multitenancy ([#149](https://github.com/dis-way/gitops-manifests/issues/149)) ([46fa62c](https://github.com/dis-way/gitops-manifests/commit/46fa62c651dbbb05df4ae5cb4d6f59435bae594c))

## [2.1.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v2.0.0...oci-linkerd-v2.1.0) (2026-01-29)


### Features

* Patch namespaces for HelmReleases ([#139](https://github.com/dis-way/gitops-manifests/issues/139)) ([3f97611](https://github.com/dis-way/gitops-manifests/commit/3f97611cfd88508312ac5cf9150fdcfcdc9aa9e5))

## [2.0.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v1.9.0...oci-linkerd-v2.0.0) (2026-01-29)


### ⚠ BREAKING CHANGES

* Split linkerd into base and overlays ([#123](https://github.com/dis-way/gitops-manifests/issues/123))

### Features

* Split linkerd into base and overlays ([#123](https://github.com/dis-way/gitops-manifests/issues/123)) ([6e9f0e3](https://github.com/dis-way/gitops-manifests/commit/6e9f0e340465da799a141181a9f8a877db42c122))

## [1.9.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v1.8.0...oci-linkerd-v1.9.0) (2026-01-19)


### Features

* update linkerd core charts to v2026 (major) ([#84](https://github.com/dis-way/gitops-manifests/issues/84)) ([cc485ff](https://github.com/dis-way/gitops-manifests/commit/cc485ff9a1f0caa094de1304ff42b7f279249219))

## [1.8.0](https://github.com/dis-way/gitops-manifests/compare/oci-linkerd-v1.7.0...oci-linkerd-v1.8.0) (2026-01-19)


### Features

* Add Linkerd HelmRelease and related configs ([#57](https://github.com/dis-way/gitops-manifests/issues/57)) ([5a3d1cc](https://github.com/dis-way/gitops-manifests/commit/5a3d1cc968fd3aa37f31d579ff000f7864f31ae2))

## [1.7.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-linkerd-v1.6.0...flux-oci-linkerd-v1.7.0) (2025-12-05)


### Features

* update linkerd core charts to v2025.11.3 ([#2760](https://github.com/Altinn/altinn-platform/issues/2760)) ([22d7abb](https://github.com/Altinn/altinn-platform/commit/22d7abbeb8ea166f57890525f3e4b55f8d8d5904))

## [1.6.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-linkerd-v1.5.0...flux-oci-linkerd-v1.6.0) (2025-12-04)


### Features

* Add Linkerd default inbound policy configuration ([#2169](https://github.com/Altinn/altinn-platform/issues/2169)) ([5b38c0d](https://github.com/Altinn/altinn-platform/commit/5b38c0dc70816a33429ad9e3feb6ccd8914eaa7c))
* Add Renovate Helmreleases detection and config ([#2493](https://github.com/Altinn/altinn-platform/issues/2493)) ([a873283](https://github.com/Altinn/altinn-platform/commit/a87328365fd08c2b050fa62757727461402726d2))


### Bug Fixes

* Increase memory requests for Linkerd and Traefik services ([#1875](https://github.com/Altinn/altinn-platform/issues/1875)) ([b65ec31](https://github.com/Altinn/altinn-platform/commit/b65ec312c94bd250f0e0deff1426810b06b52b3d))

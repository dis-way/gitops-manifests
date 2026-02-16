# Changelog

## [0.7.4](https://github.com/dis-way/gitops-manifests/compare/oci-blackbox-exporter-v0.7.3...oci-blackbox-exporter-v0.7.4) (2026-02-16)


### Bug Fixes

* fix correct placement of podAnnotations ([#394](https://github.com/dis-way/gitops-manifests/issues/394)) ([e07c5ca](https://github.com/dis-way/gitops-manifests/commit/e07c5ca1cf162af0cec8a12e654fccb0ae123f3d))

## [0.7.3](https://github.com/dis-way/gitops-manifests/compare/oci-blackbox-exporter-v0.7.2...oci-blackbox-exporter-v0.7.3) (2026-02-16)


### Bug Fixes

* add safe-to-evict to pods to signal autoscaler can evict pods ([#379](https://github.com/dis-way/gitops-manifests/issues/379)) ([767c697](https://github.com/dis-way/gitops-manifests/commit/767c697dfec081e78dc5525661296bb896a77a30))

## [0.7.2](https://github.com/dis-way/gitops-manifests/compare/oci-blackbox-exporter-v0.7.1...oci-blackbox-exporter-v0.7.2) (2026-02-10)


### Dependency Updates

* update helm release prometheus-blackbox-exporter to v11.8.0 ([#328](https://github.com/dis-way/gitops-manifests/issues/328)) ([1360ce9](https://github.com/dis-way/gitops-manifests/commit/1360ce96ad68f6c8bd0c15f804aed420ddda8d8b))

## [0.7.1](https://github.com/dis-way/gitops-manifests/compare/oci-blackbox-exporter-v0.7.0...oci-blackbox-exporter-v0.7.1) (2026-02-02)


### Dependency Updates

* update helm release prometheus-blackbox-exporter to v11.7.1 ([#189](https://github.com/dis-way/gitops-manifests/issues/189)) ([c11df80](https://github.com/dis-way/gitops-manifests/commit/c11df80c33edbd4f985bb7971d6e2db90b7b741c))

## [0.7.0](https://github.com/dis-way/gitops-manifests/compare/oci-blackbox-exporter-v0.6.0...oci-blackbox-exporter-v0.7.0) (2026-01-15)


### Features

* Add blackbox-exporter Flux OCI deployment ([#38](https://github.com/dis-way/gitops-manifests/issues/38)) ([bb7d8e4](https://github.com/dis-way/gitops-manifests/commit/bb7d8e41b05ffdd6067011a4ab27aa9fc2625b0b))

## [0.6.0](https://github.com/dis-way/gitops-manifests/compare/flux-oci-blackbox-exporter-v0.5.1...flux-oci-blackbox-exporter-v0.6.0) (2026-01-15)


### Features

* Add blackbox-exporter Flux OCI deployment ([#38](https://github.com/dis-way/gitops-manifests/issues/38)) ([bb7d8e4](https://github.com/dis-way/gitops-manifests/commit/bb7d8e41b05ffdd6067011a4ab27aa9fc2625b0b))

## [0.5.1](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.5.0...flux-oci-blackbox-exporter-v0.5.1) (2025-12-08)


### Bug Fixes

* Add probes, PDB and resources to blackbox-exporter ([#2780](https://github.com/Altinn/altinn-platform/issues/2780)) ([a83b6b2](https://github.com/Altinn/altinn-platform/commit/a83b6b27b0676801eeae589bdf685463305c2a99))

## [0.5.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.5...flux-oci-blackbox-exporter-v0.5.0) (2025-12-08)


### Features

* Add TLS probe support for extra targets altinn-uptime ([#2768](https://github.com/Altinn/altinn-platform/issues/2768)) ([ab241e8](https://github.com/Altinn/altinn-platform/commit/ab241e8dd29e52fb3c449677a114a83f32047cf0))

## [0.4.5](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.4...flux-oci-blackbox-exporter-v0.4.5) (2025-12-04)


### Bug Fixes

* altinn uptime cronjob timeout ([#2727](https://github.com/Altinn/altinn-platform/issues/2727)) ([cc8bc03](https://github.com/Altinn/altinn-platform/commit/cc8bc03746487db001bdcded0f42feab557491dc))

## [0.4.4](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.3...flux-oci-blackbox-exporter-v0.4.4) (2025-12-04)


### Bug Fixes

* Increase blackbox-exporter timeouts to 10s ([#2698](https://github.com/Altinn/altinn-platform/issues/2698)) ([3b7da0c](https://github.com/Altinn/altinn-platform/commit/3b7da0c9f179cb4965a6068fb7e3a54bbb3faf90))

## [0.4.3](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.2...flux-oci-blackbox-exporter-v0.4.3) (2025-12-03)


### Bug Fixes

* Blackbox-exporter Inline HelmRelease patch in kustomization ([#2676](https://github.com/Altinn/altinn-platform/issues/2676)) ([cecae2d](https://github.com/Altinn/altinn-platform/commit/cecae2d02c07a405b6d1f6a80858d07a0030be45))

## [0.4.2](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.1...flux-oci-blackbox-exporter-v0.4.2) (2025-12-03)


### Bug Fixes

* Unwrap HelmRelease patch and remove README deploy ([#2668](https://github.com/Altinn/altinn-platform/issues/2668)) ([57862a5](https://github.com/Altinn/altinn-platform/commit/57862a55aabdf86eb5b0d899d422ac8445747425))

## [0.4.1](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.4.0...flux-oci-blackbox-exporter-v0.4.1) (2025-12-03)


### Dependency Updates

* update helm release prometheus-blackbox-exporter to v11.5.0 ([#2656](https://github.com/Altinn/altinn-platform/issues/2656)) ([88d6f86](https://github.com/Altinn/altinn-platform/commit/88d6f86a02a4959a4283a56b024d4a1e6ffedd52))

## [0.4.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-blackbox-exporter-v0.3.0...flux-oci-blackbox-exporter-v0.4.0) (2025-11-27)


### Features

* add flux artifact for blackbox exporter ([#2405](https://github.com/Altinn/altinn-platform/issues/2405)) ([88bd99c](https://github.com/Altinn/altinn-platform/commit/88bd99cb8991de33bc2468690576f5df215181ac))
* Add Renovate Helmreleases detection and config ([#2493](https://github.com/Altinn/altinn-platform/issues/2493)) ([a873283](https://github.com/Altinn/altinn-platform/commit/a87328365fd08c2b050fa62757727461402726d2))


### Bug Fixes

* **blackbox-exporter:** update url to an existing url ([#2415](https://github.com/Altinn/altinn-platform/issues/2415)) ([cac97b8](https://github.com/Altinn/altinn-platform/commit/cac97b8247c7d8a6ffe890a351bd5c69ef062324))
* flux blackbox exporter ns linkerd enable true ([#2431](https://github.com/Altinn/altinn-platform/issues/2431)) ([7b80f7f](https://github.com/Altinn/altinn-platform/commit/7b80f7fd50ca69dab877d054b35e17e4ce9bdfd6))

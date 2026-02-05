# Changelog

## [1.3.2](https://github.com/dis-way/gitops-manifests/compare/oci-otel-collector-v1.3.1...oci-otel-collector-v1.3.2) (2026-02-05)


### Bug Fixes

* **otel-collector:** reduce sampling rate and remove unused attributes ([#293](https://github.com/dis-way/gitops-manifests/issues/293)) ([e83e2de](https://github.com/dis-way/gitops-manifests/commit/e83e2de086820bad73598b574b7ba7ee84445de6))

## [1.3.1](https://github.com/dis-way/gitops-manifests/compare/oci-otel-collector-v1.3.0...oci-otel-collector-v1.3.1) (2026-02-02)


### Bug Fixes

* **otel-collector:** set proxyProtocol to unknown for OTLP HTTP port ([#220](https://github.com/dis-way/gitops-manifests/issues/220)) ([eb97f9e](https://github.com/dis-way/gitops-manifests/commit/eb97f9e7523f835033e437ab66d06195834ffd37))

## [1.3.0](https://github.com/dis-way/gitops-manifests/compare/oci-otel-collector-v1.2.1...oci-otel-collector-v1.3.0) (2026-02-02)


### Features

* **otel-collector:** allow ingress from all meshed pods ([#212](https://github.com/dis-way/gitops-manifests/issues/212)) ([ec356c5](https://github.com/dis-way/gitops-manifests/commit/ec356c5c26dfce553080e7df24b93fb2d4a61661))

## [1.2.1](https://github.com/dis-way/gitops-manifests/compare/oci-otel-collector-v1.2.0...oci-otel-collector-v1.2.1) (2026-01-30)


### Bug Fixes

* filter noisy traefik ssl-cert error logs ([#161](https://github.com/dis-way/gitops-manifests/issues/161)) ([3c5e797](https://github.com/dis-way/gitops-manifests/commit/3c5e797501118f6153963d9c0d74fac7a92c0273))

## [1.2.0](https://github.com/dis-way/gitops-manifests/compare/oci-otel-collector-v1.1.3...oci-otel-collector-v1.2.0) (2026-01-29)


### Features

* default sampling rate is set to 10 percent ([#135](https://github.com/dis-way/gitops-manifests/issues/135)) ([e8e8fa1](https://github.com/dis-way/gitops-manifests/commit/e8e8fa1173500b5a511fcdf05d34ffcae2dbe23c))
* restructure otel manifests with base and overlays ([#132](https://github.com/dis-way/gitops-manifests/issues/132)) ([2946a6e](https://github.com/dis-way/gitops-manifests/commit/2946a6ebcfabd340ecf419a24ecd243bdcb52234))

## [1.1.3](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-collector-v1.1.2...flux-oci-otel-collector-v1.1.3) (2026-01-15)


### Bug Fixes

* add kuberneteswrapper to heavy sampling rule ([#2939](https://github.com/Altinn/altinn-platform/issues/2939)) ([29a037e](https://github.com/Altinn/altinn-platform/commit/29a037e042764e8201be4e0e7baa81388af6bc49))

## [1.1.2](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-collector-v1.1.1...flux-oci-otel-collector-v1.1.2) (2026-01-09)


### Bug Fixes

* add missing file sa-rbac.yaml to kustomization.yaml ([#2886](https://github.com/Altinn/altinn-platform/issues/2886)) ([cca844a](https://github.com/Altinn/altinn-platform/commit/cca844aa1198904c71c93a38ac49edb7f7d76d8c))

## [1.1.1](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-collector-v1.1.0...flux-oci-otel-collector-v1.1.1) (2026-01-09)


### Bug Fixes

* postbuild subsctitute replaces workload identity setup. Double $$ should result in no replace and correct value after substitute ([#2882](https://github.com/Altinn/altinn-platform/issues/2882)) ([569918b](https://github.com/Altinn/altinn-platform/commit/569918b8ef01cf7b6d3935061a7e96120338c38e))

## [1.1.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-collector-v1.0.1...flux-oci-otel-collector-v1.1.0) (2026-01-09)


### Features

* enable metrics service for otel collector ([#2830](https://github.com/Altinn/altinn-platform/issues/2830)) ([563ed10](https://github.com/Altinn/altinn-platform/commit/563ed105eb38e5d6b90a1a265cb8828eaaff50a4))

## [1.0.1](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-collector-v1.0.0...flux-oci-otel-collector-v1.0.1) (2025-11-27)


### Bug Fixes

* Point OpenTelemetry images to altinncr GHCR ([#2469](https://github.com/Altinn/altinn-platform/issues/2469)) ([32fd188](https://github.com/Altinn/altinn-platform/commit/32fd188f3c1604204639aceabcca9cb5256a4ca5))

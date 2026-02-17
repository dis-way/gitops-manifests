# Changelog

## [1.3.5](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.3.4...oci-otel-operator-v1.3.5) (2026-02-17)


### Bug Fixes

* add releaseName to multitenancy HelmReleases ([#446](https://github.com/dis-way/gitops-manifests/issues/446)) ([85a1182](https://github.com/dis-way/gitops-manifests/commit/85a1182e4c1cba6db327bbf4a9fe5d174f0a5b0c))

## [1.3.4](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.3.3...oci-otel-operator-v1.3.4) (2026-02-16)


### Bug Fixes

* move annotation reference ([#405](https://github.com/dis-way/gitops-manifests/issues/405)) ([3703221](https://github.com/dis-way/gitops-manifests/commit/370322131fc1a2e17abfebb03b45d875971899fe))

## [1.3.3](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.3.2...oci-otel-operator-v1.3.3) (2026-02-16)


### Bug Fixes

* fix correct placement of podAnnotations ([#394](https://github.com/dis-way/gitops-manifests/issues/394)) ([e07c5ca](https://github.com/dis-way/gitops-manifests/commit/e07c5ca1cf162af0cec8a12e654fccb0ae123f3d))


### Dependency Updates

* update helm release opentelemetry-operator to v0.105.1 ([#377](https://github.com/dis-way/gitops-manifests/issues/377)) ([eeaf424](https://github.com/dis-way/gitops-manifests/commit/eeaf424bef037a6c62456199b07e2495be05b795))

## [1.3.2](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.3.1...oci-otel-operator-v1.3.2) (2026-02-16)


### Bug Fixes

* add safe-to-evict to pods to signal autoscaler can evict pods ([#379](https://github.com/dis-way/gitops-manifests/issues/379)) ([767c697](https://github.com/dis-way/gitops-manifests/commit/767c697dfec081e78dc5525661296bb896a77a30))

## [1.3.1](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.3.0...oci-otel-operator-v1.3.1) (2026-02-02)


### Dependency Updates

* update helm release opentelemetry-operator to v0.105.0 ([#188](https://github.com/dis-way/gitops-manifests/issues/188)) ([72292bd](https://github.com/dis-way/gitops-manifests/commit/72292bd69345dc624e833ad2ee85cd2997a79bab))

## [1.3.0](https://github.com/dis-way/gitops-manifests/compare/oci-otel-operator-v1.2.0...oci-otel-operator-v1.3.0) (2026-01-29)


### Features

* restructure otel manifests with base and overlays ([#132](https://github.com/dis-way/gitops-manifests/issues/132)) ([2946a6e](https://github.com/dis-way/gitops-manifests/commit/2946a6ebcfabd340ecf419a24ecd243bdcb52234))

## [1.2.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-operator-v1.1.1...flux-oci-otel-operator-v1.2.0) (2026-01-09)


### Features

* enable metrics service for otel collector ([#2830](https://github.com/Altinn/altinn-platform/issues/2830)) ([563ed10](https://github.com/Altinn/altinn-platform/commit/563ed105eb38e5d6b90a1a265cb8828eaaff50a4))

## [1.1.1](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-operator-v1.1.0...flux-oci-otel-operator-v1.1.1) (2025-12-03)


### Chores

* **deps:** update helm release opentelemetry-operator to v0.99.2 ([#2611](https://github.com/Altinn/altinn-platform/issues/2611)) ([4762689](https://github.com/Altinn/altinn-platform/commit/4762689fdf2819db94fcdb07212bbe8cffbe7383))
* **main:** release flux-oci-altinn-uptime 1.0.1 ([#2671](https://github.com/Altinn/altinn-platform/issues/2671)) ([7de80df](https://github.com/Altinn/altinn-platform/commit/7de80dfbbc7d3bff83aa85b79cb11712c1850c38))

## [1.1.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-otel-operator-v1.0.0...flux-oci-otel-operator-v1.1.0) (2025-12-02)


### Features

* Add Renovate Helmreleases detection and config ([#2493](https://github.com/Altinn/altinn-platform/issues/2493)) ([a873283](https://github.com/Altinn/altinn-platform/commit/a87328365fd08c2b050fa62757727461402726d2))


### Bug Fixes

* Point OpenTelemetry images to altinncr GHCR ([#2469](https://github.com/Altinn/altinn-platform/issues/2469)) ([32fd188](https://github.com/Altinn/altinn-platform/commit/32fd188f3c1604204639aceabcca9cb5256a4ca5))

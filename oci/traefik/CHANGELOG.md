# Changelog

## [2.2.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.1.0...oci-traefik-v2.2.0) (2026-02-06)


### Features

* add gateway and linkerd polices for multitenancy ([#292](https://github.com/dis-way/gitops-manifests/issues/292)) ([a519de8](https://github.com/dis-way/gitops-manifests/commit/a519de857a47755a051916504a80444824e699b9))
* traefik trusts all IP from the AKS Vnet. ([#301](https://github.com/dis-way/gitops-manifests/issues/301)) ([ca087d2](https://github.com/dis-way/gitops-manifests/commit/ca087d29307897b63e8aac03527d0851aa31173c))
* **traefik:** support for deployment to multitenancy clusters ([#290](https://github.com/dis-way/gitops-manifests/issues/290)) ([1ded16d](https://github.com/dis-way/gitops-manifests/commit/1ded16d2e0c76a7ddc696faba875b4b44abe9079))


### Bug Fixes

* path patch removes nulled sections ([#311](https://github.com/dis-way/gitops-manifests/issues/311)) ([008aecb](https://github.com/dis-way/gitops-manifests/commit/008aecb503d5b1a0ff3b9219abbe294a75e5c30b))
* **traefik:** reduce metrics push interval from 10s to 60s ([#312](https://github.com/dis-way/gitops-manifests/issues/312)) ([ea0d92f](https://github.com/dis-way/gitops-manifests/commit/ea0d92f37d6e897668d46dea26ab32fc4aad177d))

## [2.1.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-traefik-v2.0.0...flux-oci-traefik-v2.1.0) (2026-01-15)


### Features

* enable otlp for traefik ([#2915](https://github.com/Altinn/altinn-platform/issues/2915)) ([449aced](https://github.com/Altinn/altinn-platform/commit/449aced1b381d08fd48b23d499aa85385a74be9d))

## [2.0.0](https://github.com/Altinn/altinn-platform/compare/flux-oci-traefik-v1.5.0...flux-oci-traefik-v2.0.0) (2026-01-09)


### Dependency Updates

* update helm release traefik to v38 ([#2865](https://github.com/Altinn/altinn-platform/issues/2865)) ([d579e5c](https://github.com/Altinn/altinn-platform/commit/d579e5c5dcd185d77ac40c46c849874ee580008a))

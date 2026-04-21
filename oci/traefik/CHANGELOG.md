# Changelog

## [3.2.2](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.2.1...oci-traefik-v3.2.2) (2026-04-21)


### Dependency Updates

* update helm release traefik to v39.0.8 ([#943](https://github.com/dis-way/gitops-manifests/issues/943)) ([884f49e](https://github.com/dis-way/gitops-manifests/commit/884f49e0dd6b28e4604de5a085c8361f565b570b))

## [3.2.1](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.2.0...oci-traefik-v3.2.1) (2026-04-20)


### Dependency Updates

* update helm release traefik to v39.0.7 ([#844](https://github.com/dis-way/gitops-manifests/issues/844)) ([3f861a7](https://github.com/dis-way/gitops-manifests/commit/3f861a76471c31c2cf5849695dcc98fd6775d168))

## [3.2.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.1.0...oci-traefik-v3.2.0) (2026-03-26)


### Features

* Add AKS subnet CIDRs to Traefik trusted list ([#828](https://github.com/dis-way/gitops-manifests/issues/828)) ([3a0dd6c](https://github.com/dis-way/gitops-manifests/commit/3a0dd6cf44d44b69ef85edebd6709cb91ea1b2b5))

## [3.1.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.0.1...oci-traefik-v3.1.0) (2026-03-25)


### Features

* add platform-aks overlay ([#811](https://github.com/dis-way/gitops-manifests/issues/811)) ([26353dd](https://github.com/dis-way/gitops-manifests/commit/26353ddd8f6627d2c71fb010d42fda091f7ee73c))

## [3.1.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.0.1...oci-traefik-v3.1.0) (2026-03-25)


### Features

* add platform-aks overlay ([#811](https://github.com/dis-way/gitops-manifests/issues/811)) ([26353dd](https://github.com/dis-way/gitops-manifests/commit/26353ddd8f6627d2c71fb010d42fda091f7ee73c))

## [3.0.1](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v3.0.0...oci-traefik-v3.0.1) (2026-03-23)


### Dependency Updates

* update helm release traefik to v39.0.6 ([#789](https://github.com/dis-way/gitops-manifests/issues/789)) ([71a87b6](https://github.com/dis-way/gitops-manifests/commit/71a87b660b44818b9590bf4a756c8c180b9443b5))

## [3.0.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.4.0...oci-traefik-v3.0.0) (2026-03-20)


### ⚠ BREAKING CHANGES

* migrate from traefik crds chart and bump version ([#772](https://github.com/dis-way/gitops-manifests/issues/772))

### Features

* migrate from traefik crds chart and bump version ([#772](https://github.com/dis-way/gitops-manifests/issues/772)) ([2c64575](https://github.com/dis-way/gitops-manifests/commit/2c6457523044659607a9c4143129115d6bc068f6))

## [2.4.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.3.2...oci-traefik-v2.4.0) (2026-03-11)


### Features

* **headscale:** Expose DERP via LoadBalancer ([#696](https://github.com/dis-way/gitops-manifests/issues/696)) ([b3b9c6d](https://github.com/dis-way/gitops-manifests/commit/b3b9c6dec2d4606fae2b916575aa09b3d215ea84))

## [2.3.2](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.3.1...oci-traefik-v2.3.2) (2026-02-19)


### Features

* **traefik:** Add adminservices kustomization ([#497](https://github.com/dis-way/gitops-manifests/issues/497)) ([529664f](https://github.com/dis-way/gitops-manifests/commit/529664f6e8f0f2bfb1b854d57a4f164199ef7eee))

## [2.3.1](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.3.0...oci-traefik-v2.3.1) (2026-02-17)


### Bug Fixes

* add releaseName to multitenancy HelmReleases ([#446](https://github.com/dis-way/gitops-manifests/issues/446)) ([85a1182](https://github.com/dis-way/gitops-manifests/commit/85a1182e4c1cba6db327bbf4a9fe5d174f0a5b0c))

## [2.3.0](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.2.1...oci-traefik-v2.3.0) (2026-02-17)


### Features

* **traefik:** Include AKS pod CIDRs in policies ([#433](https://github.com/dis-way/gitops-manifests/issues/433)) ([36c86b2](https://github.com/dis-way/gitops-manifests/commit/36c86b2711173686e0ea97b5fdc2b32d90103bc7))

## [2.2.1](https://github.com/dis-way/gitops-manifests/compare/oci-traefik-v2.2.0...oci-traefik-v2.2.1) (2026-02-12)


### Bug Fixes

* **oci/traefik:** unquote DEFAULT_GATEWAY_HOSTNAME ([#364](https://github.com/dis-way/gitops-manifests/issues/364)) ([e947e7a](https://github.com/dis-way/gitops-manifests/commit/e947e7a5aebbd96cf57f027c558bdd4c2fa65d44))

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

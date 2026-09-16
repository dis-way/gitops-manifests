# Changelog

## [2.3.0](https://github.com/dis-way/gitops-manifests/compare/oci-envoy-gateway-v2.2.0...oci-envoy-gateway-v2.3.0) (2026-09-16)


### Features

* **envoy-gateway:** back global rate limiting with Valkey ([#1590](https://github.com/dis-way/gitops-manifests/issues/1590)) ([d462036](https://github.com/dis-way/gitops-manifests/commit/d462036f00693c04f35281f73d454db81c4609a3))

## [2.2.0](https://github.com/dis-way/gitops-manifests/compare/oci-envoy-gateway-v2.1.1...oci-envoy-gateway-v2.2.0) (2026-09-15)


### Features

* drop more headers in edge proxy ([#1578](https://github.com/dis-way/gitops-manifests/issues/1578)) ([d71a753](https://github.com/dis-way/gitops-manifests/commit/d71a75381d0470097dba1c480681fa3b1786a79a))
* **envoy-gateway:** make the cpu and memory request/limit configurable with default ([#1581](https://github.com/dis-way/gitops-manifests/issues/1581)) ([f48574b](https://github.com/dis-way/gitops-manifests/commit/f48574bdd30908c77a122b7f3a91dbd9b964da4d))


### Bug Fixes

* **envoy-gateway:** add tags to otel traces to improve visualization ([#1583](https://github.com/dis-way/gitops-manifests/issues/1583)) ([6af93dd](https://github.com/dis-way/gitops-manifests/commit/6af93dd6a376b16b19b39c5e47e08e8a02237b1e))

## [2.1.1](https://github.com/dis-way/gitops-manifests/compare/oci-envoy-gateway-v2.1.0...oci-envoy-gateway-v2.1.1) (2026-09-14)


### Bug Fixes

* set resources request and limit explicitly ([#1565](https://github.com/dis-way/gitops-manifests/issues/1565)) ([2e83cb4](https://github.com/dis-way/gitops-manifests/commit/2e83cb43bccc97180094b674e82dfb4860aa41a5))

## [2.1.0](https://github.com/dis-way/gitops-manifests/compare/oci-envoy-gateway-v2.0.0...oci-envoy-gateway-v2.1.0) (2026-09-12)


### Features

* **envoy-gateway:** set X-Real-IP and strip inbound X-Forwarded-For ([#1531](https://github.com/dis-way/gitops-manifests/issues/1531)) ([b32ae15](https://github.com/dis-way/gitops-manifests/commit/b32ae15a5bcec5574f0f8f445d014b29501f45a2))

## [2.0.0](https://github.com/dis-way/gitops-manifests/compare/oci-envoy-gateway-v1.0.0...oci-envoy-gateway-v2.0.0) (2026-09-11)


### ⚠ BREAKING CHANGES

* **envoy-gateway:** the multitenancy layer is removed; use edge instead.

### Features

* **envoy-gateway:** add default gateway and split into layers  ([#1526](https://github.com/dis-way/gitops-manifests/issues/1526)) ([d1e57e7](https://github.com/dis-way/gitops-manifests/commit/d1e57e73c39d9be3b803c7175641bd63e1918961))

## 1.0.0 (2026-09-10)


### Features

* **envoy-gateway:** add Envoy Gateway with initial configuration ([#1502](https://github.com/dis-way/gitops-manifests/issues/1502)) ([1f49b98](https://github.com/dis-way/gitops-manifests/commit/1f49b98d25687e8b9e3a1399675b85e987e1ecfb))

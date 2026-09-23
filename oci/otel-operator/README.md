# OTel Operator

Deploys the OpenTelemetry Operator, which reconciles the `OpenTelemetryCollector` in `oci/otel-collector` and injects OpenTelemetry SDK configuration into pods that opt in with an annotation.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR (for policies) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR (for policies) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for policies) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for policies) |

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, HelmRepository and HelmRelease: two replicas behind a PDB, admission webhooks enabled |
| `apps` | Alias for `base`; no additional changes |
| `multitenancy` | `base` + `policies`, with the HelmRelease and HelmRepository in `platform-system` targeting `monitoring` |
| `policies` | Linkerd authorization policy letting kube-apiserver reach the admission webhook |

## Dependencies

- `cert-manager`, including cainjector, must be running before the operator starts. The webhook serving certificate comes from a chart-managed self-signed `Issuer` and is mounted unconditionally, so until it is issued the operator pod stays in `ContainerCreating` — and the collector, which the operator reconciles, stops being reconciled with it. The Flux `Kustomization` for this package should `dependsOn` cert-manager.

## Admission Webhooks

Pod SDK injection (`instrumentation.opentelemetry.io/inject-sdk`) is implemented by the `mpod.kb.io` webhook. The chart cannot enable that webhook on its own — `admissionWebhooks.create` turns on all seven:

| Webhook | Resource | Operations | failurePolicy |
|---------|----------|------------|---------------|
| `mpod.kb.io` | `pods` | CREATE | `Ignore` |
| `minstrumentation.kb.io` | `instrumentations` | CREATE, UPDATE | `Fail` |
| `mopentelemetrycollectorbeta.kb.io` | `opentelemetrycollectors` | CREATE, UPDATE | `Fail` |
| `vinstrumentationcreateupdate.kb.io` | `instrumentations` | CREATE, UPDATE | `Fail` |
| `vopentelemetrycollectorcreateupdatebeta.kb.io` | `opentelemetrycollectors` | CREATE, UPDATE | `Fail` |
| `vinstrumentationdelete.kb.io` | `instrumentations` | DELETE | `Ignore` |
| `vopentelemetrycollectordeletebeta.kb.io` | `opentelemetrycollectors` | DELETE | `Ignore` |

- **Pod injection fails open.** If the operator is unavailable, or the annotation names an `Instrumentation` that does not exist, the pod is admitted without the `OTEL_*` environment. The only trace is an error in the operator log.
- **CR validation fails closed.** An `Instrumentation` or `OpenTelemetryCollector` the operator rejects cannot be applied, and neither can any change to one while the operator is down.
- **The `OpenTelemetryCollector` CRD gets a conversion webhook** (`/convert`). The chart renders its CRDs as ordinary templates, so this lands on every cluster when the webhooks are enabled and is removed again if they are disabled. The API server only calls it to convert between `v1alpha1` and `v1beta1`; the collector is authored and stored as `v1beta1`.
- **One `namespaceSelector` is shared by all seven webhooks.** It excludes namespaces labelled `control-plane`, the exclusion AKS documents. Every other pod CREATE in the cluster reaches the operator, but only annotated pods are changed.
- **Ordering with Linkerd.** The API server runs mutating webhook configurations in name order, so `dis-otel-operator-opentelemetry-operator-mutation` runs before `linkerd-proxy-injector-webhook-config`. That is why the operator's default target, `.spec.containers[0]`, is still the application container: Linkerd inserts `linkerd-proxy` at index 0 only afterwards. Renaming the release or setting `admissionWebhooks.namePrefix` can change this.

Keep `crds.create` at its default of `true`. The CRDs are part of the Helm release and carry no `helm.sh/resource-policy: keep`, so dropping them from the release deletes them — together with every `OpenTelemetryCollector` and `Instrumentation` in the cluster.

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
- The Flux `Kustomization` for the `multitenancy` layer must set `spec.postBuild` and supply `AKS_VNET_IPV4_CIDR` and `AKS_VNET_IPV6_CIDR`. Without `postBuild` no substitution runs at all, so even the defaulted pod CIDRs stay literal; Linkerd then rejects the `NetworkAuthentication`, and nothing in the package applies.
- `oci/otel-collector` depends on this package: its Flux `Kustomization` should `dependsOn` this one (see *CR validation fails closed* below).

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

- **Pod injection fails open.** If the operator is unreachable, kube-apiserver admits the pod without it; that is visible only on the API server side, e.g. its `apiserver_admission_webhook_fail_open_count` metric. If the annotation names an `Instrumentation` that does not exist, the operator logs an error and admits the pod unchanged. Either way the pod runs without the `OTEL_*` environment.
- **CR validation fails closed.** An `Instrumentation` or `OpenTelemetryCollector` the operator rejects cannot be applied. Flux also dry-runs every object on every reconciliation, so while the operator is unreachable none of `oci/otel-collector` reconciles — its ExternalSecret and RBAC included — even when nothing changed.
- **The `OpenTelemetryCollector` CRD gets a conversion webhook** (`/convert`). The chart renders its CRDs as ordinary templates, so this lands on every cluster when the webhooks are enabled and is removed again if they are disabled. The API server only calls it to convert between `v1alpha1` and `v1beta1`; the collector is authored and stored as `v1beta1`.
- **One `namespaceSelector` is shared by all seven webhooks.** It excludes namespaces labelled `control-plane`, the exclusion AKS documents. Every other pod CREATE in the cluster reaches the operator, but only annotated pods are changed.
- **Every pod is round-tripped through the operator.** The webhook decodes each pod, annotated or not, into the operator's `corev1.Pod` type and answers with a patch from the original to the re-encoded pod. Pod fields newer than the operator's Kubernetes client libraries would be dropped, so keep the operator current before moving AKS to a new Kubernetes minor version.
- **Linkerd.** Without `instrumentation.opentelemetry.io/container-names` the operator targets `.spec.containers[0]`. Linkerd injects `linkerd-proxy` as a native sidecar in `.spec.initContainers`, so that is the application container. A workload that sets `config.linkerd.io/proxy-enable-native-sidecar: "false"` gets the proxy at `containers[0]` instead, and is still safe only because the API server runs mutating webhook configurations in name order: `dis-otel-operator-opentelemetry-operator-mutation` sorts before `linkerd-proxy-injector-webhook-config`. Renaming the release or setting `admissionWebhooks.namePrefix` could change that.

Keep `crds.create` at its default of `true`. The CRDs are part of the Helm release and carry no `helm.sh/resource-policy: keep`, so dropping them from the release deletes them — together with every `OpenTelemetryCollector` and `Instrumentation` in the cluster.

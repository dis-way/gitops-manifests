# Envoy Gateway

Deploys Envoy Gateway, a Kubernetes Gateway API implementation, via a Flux HelmRelease.

## Variables

All variables are consumed by the `default-gateway` layer; `base` needs none.

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_LB_PIP4_NAME` | - | Yes | Name of the pre-provisioned Azure IPv4 public IP bound to the Envoy `LoadBalancer` Service |
| `AKS_LB_PIP6_NAME` | - | Yes | Name of the pre-provisioned Azure IPv6 public IP bound to the Envoy `LoadBalancer` Service |
| `AKS_NAME` | - | Yes | Cluster name, emitted as the literal `source` tag on every trace span |
| `BASE_HOSTNAME` | - | Yes | Hostname for the platform's own HTTPS/HTTP listeners on the `eg` Gateway |
| `DIS_TLS_KV_URI` | - | Yes | Azure Key Vault URL holding the platform TLS certificate |
| `DIS_TLS_READER_CLIENT_ID` | - | Yes | Client ID of the workload-identity UAMI that reads the Key Vault |
| `DIS_TLS_READER_TENANT_ID` | - | Yes | Tenant ID for that workload identity |
| `DIS_TLS_CRT_SECRET_NAME` | - | Yes | Key Vault secret name holding the certificate, synced to `tls.crt` |
| `DIS_TLS_KEY_SECRET_NAME` | - | Yes | Key Vault secret name holding the private key, synced to `tls.key` |

## Layers

| Path | Description |
|------|-------------|
| `base` | Control plane only: Namespace (`envoy-gateway-system`), OCI HelmRepository, and HelmRelease installing the `gateway-helm` chart. All images (control plane, certgen, shutdown manager, rate limit, and the Envoy data plane) are mirrored through `altinncr.azurecr.io` via `global.imageRegistry` |
| `default-gateway` | Data plane: the `eg` EnvoyProxy, the `eg` GatewayClass and Gateway, the External Secrets wiring that syncs the `tls-cert` Secret from Azure Key Vault, a ClientTrafficPolicy and BackendTrafficPolicy covering the whole Gateway, and an HTTPRoute redirecting `:80` to HTTPS. Depends on the namespace from `base` |
| `edge` | `base` + `default-gateway`, with the HelmRepository/HelmRelease moved to `platform-system` and the chart deployed into `envoy-gateway-system` via `targetNamespace`/`releaseName`. The full install for a cluster that serves traffic |

## Notes

- CRDs are not managed by this package (`crds.enabled: false`, `install.crds: Skip` / `upgrade.crds: Skip`); both the Gateway API and Envoy Gateway CRDs must already be present in the cluster. Envoy Gateway v1.9 requires **Gateway API v1.6** CRDs, standard channel. The `default-gateway` layer additionally requires the External Secrets Operator CRDs (`external-secrets.io/v1`).
- The `eg` EnvoyProxy in `default-gateway` configures the data plane: dual-stack, `externalTrafficPolicy: Local` (load-bearing for client IP detection on Azure), hostname topology spread, a PDB, an HPA at 3-10 replicas on 50% CPU, and OpenTelemetry metrics and tracing to `otel-collector.monitoring`.
- `client-traffic-policy.yaml` holds the edge hardening: `directSourceIP` client IP detection (which depends on `externalTrafficPolicy: Local` in the EnvoyProxy — change the two together), connection limits, the slowloris/slow-POST timeouts, and an HSTS response header (`max-age=31536000; includeSubDomains`, no `preload`). `backend-traffic-policy.yaml` holds a catch-all local rate limit. Both target the Gateway, so listeners added later by ListenerSets inherit them unless a ListenerSet-scoped policy overrides.
- Metrics use an inclusion list — a stat not matched by `telemetry.metrics.matches` is not produced at all. Add to the list rather than trimming it if a dashboard goes blank.
- `edge` places the control plane in `platform-system`, which this package does not create — it must already exist. The root `kustomization.yaml` and `base` instead leave the HelmRelease in `envoy-gateway-system`, so the two paths are not interchangeable on a live cluster: switching between them moves the Helm release between namespaces.
- The Gateway's `https` listener references the `tls-cert` Secret produced by the ExternalSecret in the same layer. Until External Secrets has synced it, the listener reports `ResolvedRefs=False`; this resolves on its own once the Secret appears.

## Listener delegation

Teams add their own listeners without changing this package. The `eg` Gateway sets `allowedListeners.namespaces.from: All`, so a team creates a `ListenerSet` in its own namespace with a `parentRef` back to `eg`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: ListenerSet
metadata:
  name: team-listeners
  namespace: team-a
spec:
  parentRef:
    group: gateway.networking.k8s.io
    kind: Gateway
    name: eg
    namespace: envoy-gateway-system
  listeners:
    - name: https
      protocol: HTTPS
      port: 443
      hostname: team-a.example.com
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: team-a-tls
```

- The TLS Secret is read from the ListenerSet's own namespace, so no ReferenceGrant is needed.
- Routes attach to the `ListenerSet` as their `parentRef`, not to the Gateway.
- Listeners are distinct on the tuple `(port, protocol, hostname)` across the Gateway and every attached ListenerSet, so port 443 is available to every team provided each brings a unique hostname. Duplicate tuples are rejected, not merged — hostname allocation remains a platform concern. In particular, `443/HTTPS/${BASE_HOSTNAME}` is already taken by the Gateway itself.
- The `:80`→HTTPS redirect is pinned to the Gateway's own `http` listener via `sectionName`, so it does not cover listeners contributed by ListenerSets. A team exposing an HTTP listener needs its own redirect HTTPRoute with a `parentRef` to that ListenerSet.
- `ListenerSet` is standard channel `gateway.networking.k8s.io/v1` and needs no Envoy Gateway feature flag. The older experimental `XListenerSet` is not used.
- Gateway API v1.6 still enforces `minItems: 1` on `spec.listeners`, so the `eg` Gateway must keep at least one listener of its own — it cannot delegate everything to ListenerSets.

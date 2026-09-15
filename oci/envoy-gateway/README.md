# Envoy Gateway

Deploys Envoy Gateway, a Kubernetes Gateway API implementation, via a Flux HelmRelease.

## Variables

Most variables are consumed by the `default-gateway` layer; the `VALKEY_*` pair is consumed by
`valkey`. `base` needs none.

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
| `ENVOY_CPU_REQUEST` | `1` | No | CPU request per Envoy data plane pod. No CPU limit is set |
| `ENVOY_MEMORY_REQUEST` | `512Mi` | No | Memory request per Envoy data plane pod. The memory limit is set to the same value |
| `VALKEY_CPU_REQUEST` | `1` | No | CPU request for the Valkey pod backing global rate limiting. No CPU limit is set |
| `VALKEY_MEMORY_REQUEST` | `1Gi` | No | Memory request for the Valkey pod. The memory limit is set to the same value |

## Layers

| Path | Description |
|------|-------------|
| `base` | Control plane only: Namespace (`envoy-gateway-system`), OCI HelmRepository, and HelmRelease installing the `gateway-helm` chart. All images (control plane, certgen, shutdown manager, rate limit, and the Envoy data plane) are mirrored through `altinncr.azurecr.io` via `global.imageRegistry` |
| `default-gateway` | Data plane: the `eg` EnvoyProxy, the `eg` GatewayClass and Gateway, the External Secrets wiring that syncs the `tls-cert` Secret from Azure Key Vault, a ClientTrafficPolicy and BackendTrafficPolicy covering the whole Gateway, and an HTTPRoute redirecting `:80` to HTTPS. Depends on the namespace from `base` |
| `valkey` | The Valkey instance backing **global** rate limiting: Namespace (`envoy-valkey`), a NetworkPolicy restricting access to the ratelimit pods, HelmRepository, and HelmRelease installing the `valkey` chart, mirrored through `altinncr.azurecr.io` |
| `edge` | `valkey` + `base` + `default-gateway`, with every HelmRepository/HelmRelease moved to `platform-system` and each chart deployed into its own namespace via `targetNamespace`/`releaseName`. This layer also adds the `rateLimit` Redis backend to the control plane config and a `dependsOn` from `envoy-gateway` to `valkey`. The full install for a cluster that serves traffic |

## Notes

- CRDs are not managed by this package (`crds.enabled: false`, `install.crds: Skip` / `upgrade.crds: Skip`); both the Gateway API and Envoy Gateway CRDs must already be present in the cluster. Envoy Gateway v1.9 requires **Gateway API v1.6** CRDs, standard channel. The `default-gateway` layer additionally requires the External Secrets Operator CRDs (`external-secrets.io/v1`).
- The `eg` EnvoyProxy in `default-gateway` configures the data plane: dual-stack, `externalTrafficPolicy: Local` (load-bearing for client IP detection on Azure), hostname topology spread, a PDB, an HPA at 3-10 replicas on 50% CPU, and OpenTelemetry metrics and tracing to `otel-collector.monitoring`.
- Data plane sizing is set by `ENVOY_CPU_REQUEST` and `ENVOY_MEMORY_REQUEST`. The memory limit always mirrors `ENVOY_MEMORY_REQUEST` — there is no separate limit variable, so more headroom means raising the request. CPU is request-only by design; a CPU limit would throttle the data plane and surface as latency on every route at once. Raising the CPU request also raises the absolute CPU the HPA's 50% utilization target corresponds to, so a larger request scales out later, not sooner.
- `client-traffic-policy.yaml` holds the edge hardening: `directSourceIP` client IP detection (which depends on `externalTrafficPolicy: Local` in the EnvoyProxy — change the two together), connection limits, the slowloris/slow-POST timeouts, an `X-Real-IP` request header set from the client address (with any client-supplied `X-Forwarded-For` stripped first, so Envoy's own entry is the only one), and an HSTS response header (`max-age=31536000; includeSubDomains`, no `preload`). `backend-traffic-policy.yaml` holds a catch-all local rate limit. Both target the Gateway, so listeners added later by ListenerSets inherit them unless a ListenerSet-scoped policy overrides.
- Metrics use an inclusion list — a stat not matched by `telemetry.metrics.matches` is not produced at all. Add to the list rather than trimming it if a dashboard goes blank.
- Envoy tags spans with the pre-1.0 OpenTracing names (`http.method`, `http.url`, `http.status_code`) and sends them all as strings, which no current trace backend reads ([envoyproxy/envoy#30821](https://github.com/envoyproxy/envoy/issues/30821)). `telemetry.tracing.tags` adds the semantic-convention attributes that cannot be recovered downstream — the upstream (egress) span carries no URL at all — and `transform/envoy` in `oci/otel-collector` translates the rest. The two are a pair: changing the tag names here without changing that processor sends Envoy requests back to showing up in Application Insights as a request named `ingress` with no URL.
- Global rate limiting is configured **only** in `edge` — the `rateLimit.backend` Redis config and the `valkey` layer are wired together there, so the root `kustomization.yaml` and `base` stay deployable on their own with no Valkey. The catch-all *local* rate limit in `default-gateway/backend-traffic-policy.yaml` is independent of this and needs no backing store.
- Valkey has **no authentication and no TLS** — `network-policy.yaml` is the only thing restricting access to it. The policy allows ingress to 6379 only from pods labelled `app.kubernetes.io/name: envoy-ratelimit` in `envoy-gateway-system`; everything else is denied. This was a deliberate trade: without TLS a Valkey password travels in plaintext anyway, so it adds nothing against an attacker who can sniff pod traffic and nothing against one who can schedule a pod, while costing a Key Vault secret, External Secrets as a new precondition for `edge`, and probe overrides (the chart's `valkey-cli ping` probes are auth-unaware and crash-loop once the `default` user has a password). The intended follow-up is cert-manager plus TLS and ACL users together, not a plaintext password now. If auth is revisited: Envoy Gateway's `RateLimitRedisSettings` has no password field and credentials must **not** go in `redis.url` (it is passed verbatim as a dial address) — the supported path is a `REDIS_AUTH` env var, value `default:<password>`, injected through `config.envoyGateway.provider.kubernetes.rateLimitDeployment.container.env`, with the Secret in `envoy-gateway-system`.
- Because that NetworkPolicy selects the Valkey pod, **all** other ingress to it is denied. That is fine today — the chart's default probes are `exec` (`valkey-cli ping`), which is not network traffic. But setting `metrics.enabled: true` later would silently break the exporter sidecar's `tcpSocket` probes and Prometheus/AMA scraping until a second ingress rule is added for the metrics port.
- Valkey runs as a single replica with no persistence (`emptyDir`) and no PDB, on purpose: losing a counter bucket on restart is preferable to the write latency and in-memory CPU cost of replication. Expect global rate-limit counters to reset whenever the Valkey pod is replaced.
- Changing `config.envoyGateway` only rewrites the `envoy-gateway-config` ConfigMap. The `gateway-helm` Deployment carries no `checksum/config` annotation, and Envoy Gateway reads that file at startup without hot-reloading it, so **the control plane does not roll on its own** — run `kubectl rollout restart deployment/envoy-gateway -n envoy-gateway-system` after a config change lands. The `envoy-ratelimit` Deployment is then provisioned fresh by the infra manager, and the data plane picks the change up over xDS; neither needs a manual restart.
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

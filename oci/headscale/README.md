# Headscale

Self-hosted Tailscale control server providing WireGuard-based VPN mesh networking with OIDC authentication via Microsoft Entra.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `AKS_NODE_RG` | - | Yes | Azure node resource group containing the public IP (shared with Traefik) |
| `PUBLIC_IP_V4` | - | Yes | Public IPv4 address for the DERP server and LoadBalancer (shared with Traefik) |
| `PUBLIC_IP_V6` | - | Yes | Public IPv6 address for the DERP LoadBalancer and headscale DERP config |
| `HEADSCALE_APP_CLIENT_ID` | - | Yes | Microsoft Entra OIDC client ID |
| `HEADSCALE_APP_CLIENT_SECRET` | - | Yes | Microsoft Entra OIDC client secret — source from a secret store, not plain substitution |
| `HEADSCALE_APP_ALLOWED_GROUP` | - | Yes | Microsoft Entra group allowed for access |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR, trusted for forwarded client-IP headers |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR, trusted for forwarded client-IP headers |

## Layers

| Path | Description |
|------|-------------|
| `.` | Core resources: namespace, config, storage, deployment, services, gateway, and HTTPRoute |
| `post-deploy` | cert-manager Certificate for Let's Encrypt TLS |
| `policies` | Included by the root kustomization. Default-deny NetworkPolicies (enforced by Cilium) allowing only Traefik, headplane, STUN from the internet, Entra ID, the Tailscale DERP map and metrics scraping (ama-metrics, otel collector). Blocks the gRPC admin API (50443) entirely |
| `acl-sync` | Optional. Applies the ACL policy from Git, see [ACL policy](#acl-policy). Requires External Secrets Operator with the `dis-system-store` SecretStore in `flux-system` (`oci/external-secrets-operator` `adminservices/post-deploy`) |

## ACL policy

The ACL policy (`policy.mode: database`) comes from Git: `tf/adminservices-prod/headscale-access` in [dis-way/adminservices](https://github.com/dis-way/adminservices) renders it into the Key Vault secret `headscale-acl` in the dis-system Key Vault ([RFC 0020](https://github.com/Altinn/altinn-platform/pull/4233)).

| Resource | Namespace | Description |
|----------|-----------|-------------|
| ExternalSecret `headscale-acl` | `flux-system` | Syncs the Key Vault secret to the Secret `headscale-acl` every 5 minutes |
| CronJob `headscale-acl-apply` | `headscale` | Every 5 minutes: compares the Secret with `headscale policy get`. If they differ, logs the diff, runs `headscale policy check` against the live users and nodes, then `headscale policy set` |

The CronJob runs the `headscale` CLI in the Headscale pod with `kubectl exec` over the unix socket, so it needs no API key and the gRPC API stays on loopback. Its Role allows `pods/exec` in `headscale` and `get` on only the `headscale-acl` Secret in `flux-system`. Its only egress is DNS and the API server.

Git wins: an edit made in Headplane or with the CLI lasts until the next run, at most 5 minutes, and the job log shows what was overwritten. An invalid policy fails the run and leaves the live policy unchanged.

```sh
# Run now, for example after an emergency edit of the Key Vault secret
kubectl annotate externalsecret headscale-acl -n flux-system force-sync=$(date +%s) --overwrite
kubectl create job -n headscale --from=cronjob/headscale-acl-apply headscale-acl-apply-manual
```

## Extra DNS Records

Extra DNS records are served to Tailscale clients via headscale. By default, the `headscale-extra-records` ConfigMap contains an empty array. Patch it in your overlay to add static entries:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: headscale-extra-records
  namespace: headscale
data:
  extra-records.json: |
    [
      {"name": "grafana.ts.altinn.cloud", "type": "A", "value": "100.64.0.3"},
      {"name": "prometheus.ts.altinn.cloud", "type": "A", "value": "100.64.0.4"}
    ]
```

Headscale polls `extra-records.json` via checksum and picks up changes without a restart. Sort the JSON keys and records to produce stable output when generating the file with a script.

## DERP Map

Clients get DERP regions from two sources, merged by headscale:

| Source | Regions |
|--------|---------|
| Embedded DERP server (`derp.server`) | 999 (`headscale-server`) |
| `headscale-derp-map` ConfigMap (`derp.paths`) | 900–998: standalone relays from the `oci/derper` package |

`derp.urls` is empty: the public Tailscale DERP servers are not used. Keep at least two standalone regions in other clusters, so clients have a relay when the headscale pod restarts.

Headscale fails to start if a file in `derp.paths` does not parse, so test changes to `derp.yaml` before release. A pod restart always picks up ConfigMap changes.

## Prerequisites

### DNS

Add a CNAME record in the `altinn.cloud` zone to delegate the ACME DNS-01 challenge to the Azure DNS zone managed by cert-manager:

```
_acme-challenge.headscale.altinn.cloud  CNAME  _acme-challenge.headscale.altinn.cloud.prod.admin.altinn.cloud
```

This is required before deploying `post-deploy/`, as cert-manager will use DNS-01 via the delegated zone to issue the certificate from `letsencrypt-production`.

## Usage

Two Flux `Kustomization` resources are required: one for the main package and one for `post-deploy/`, which requests the TLS certificate. The `post-deploy` Kustomization sets `wait: false` so cert-manager can issue the certificate asynchronously without blocking health checks.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: headscale
spec:
  path: .
  postBuild:
    substitute:
      AKS_NODE_RG: "MC_my-rg_my-aks_norwayeast"
      PUBLIC_IP_V4: "203.0.113.1"
      PUBLIC_IP_V6: "2001:db8::1"
      HEADSCALE_APP_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
      HEADSCALE_APP_CLIENT_SECRET: "secret"
      HEADSCALE_APP_ALLOWED_GROUP: "00000000-0000-0000-0000-000000000000"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: headscale-post-deploy
spec:
  path: ./post-deploy
  wait: false
  dependsOn:
    - name: headscale
```

To apply the ACL policy from Git, add a third Kustomization for `acl-sync/`. It sets `wait: false` so a failing ExternalSecret does not block the others.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: headscale-acl-sync
spec:
  path: ./acl-sync
  prune: true
  wait: false
  dependsOn:
    - name: headscale
```

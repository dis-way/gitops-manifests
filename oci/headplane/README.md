# Headplane

Web UI for managing the headscale control server, authenticated via Microsoft Entra OIDC.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `HEADPLANE_APP_CLIENT_ID` | - | Yes | Microsoft Entra OIDC client ID for headplane |
| `HEADPLANE_APP_CLIENT_SECRET` | - | Yes | Microsoft Entra OIDC client secret — source from a secret store, not plain substitution |
| `HEADPLANE_COOKIE_SECRET` | - | Yes | Random secret used to sign headplane session cookies |
| `HEADPLANE_API_KEY` | - | Yes | Headscale API key used by headplane to manage the control server |

## Layers

| Path | Description |
|------|-------------|
| `.` | Core resources: namespace, secret, deployment, service, gateway, and HTTPRoute |
| `post-deploy` | cert-manager Certificate for Let's Encrypt TLS |

## Prerequisites

### DNS

Two records are required in the `altinn.cloud` zone:

1. **Service record** — points the hostname at the Traefik load balancer (same IP used by Traefik and headscale):

```
headplane.altinn.cloud  A     <PUBLIC_IP_V4>
headplane.altinn.cloud  AAAA  <PUBLIC_IP_V6>
```

2. **ACME delegation** — delegates the DNS-01 challenge to the Azure DNS zone managed by cert-manager:

```
_acme-challenge.headplane.altinn.cloud  CNAME  _acme-challenge.headplane.altinn.cloud.prod.admin.altinn.cloud
```

The ACME delegation must be in place before deploying `post-deploy/`, as cert-manager uses DNS-01 via the delegated zone to issue the certificate from `letsencrypt-production`.

Two Flux `Kustomization` resources are required: one for the main package and one for `post-deploy/`, which requests the TLS certificate. The `post-deploy` Kustomization sets `wait: false` so cert-manager can issue the certificate asynchronously without blocking health checks.

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: headplane
spec:
  path: .
  postBuild:
    substitute:
      HEADPLANE_APP_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
      HEADPLANE_APP_CLIENT_SECRET: "secret"
      HEADPLANE_COOKIE_SECRET: "random-32-char-string"
      HEADPLANE_API_KEY: "hskey-api-..."
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: headplane-post-deploy
spec:
  path: ./post-deploy
  wait: false
  dependsOn:
    - name: headplane
```

# Headscale

Self-hosted Tailscale control server providing WireGuard-based VPN mesh networking with OIDC authentication via Microsoft Entra.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `PUBLIC_IP_V4` | - | Yes | Public IPv4 address for the DERP server |
| `PUBLIC_IP_V6` | - | Yes | Public IPv6 address for the DERP server |
| `HEADSCALE_APP_CLIENT_ID` | - | Yes | Microsoft Entra OIDC client ID |
| `HEADSCALE_APP_CLIENT_SECRET` | - | Yes | Microsoft Entra OIDC client secret — source from a secret store, not plain substitution |
| `HEADSCALE_APP_ALLOWED_GROUP` | - | Yes | Microsoft Entra group allowed for access |

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

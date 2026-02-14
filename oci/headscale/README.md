# Headscale

Self-hosted Tailscale control server providing WireGuard-based VPN mesh networking with OIDC authentication via Microsoft Entra.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `PUBLIC_IP_V4` | - | Yes | Public IPv4 address for the DERP server |
| `PUBLIC_IP_V6` | - | Yes | Public IPv6 address for the DERP server |
| `HEADSCALE_APP_CLIENT_ID` | - | Yes | Microsoft Entra OIDC client ID |
| `HEADSCALE_APP_CLIENT_SECRET` | - | Yes | Microsoft Entra OIDC client secret |
| `HEADSCALE_APP_ALLOWED_GROUP` | - | Yes | Microsoft Entra group allowed for access |

## Usage

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
spec:
  path: .
  postBuild:
    substitute:
      PUBLIC_IP_V4: "203.0.113.1"
      PUBLIC_IP_V6: "2001:db8::1"
      HEADSCALE_APP_CLIENT_ID: "00000000-0000-0000-0000-000000000000"
      HEADSCALE_APP_CLIENT_SECRET: "secret"
      HEADSCALE_APP_ALLOWED_GROUP: "00000000-0000-0000-0000-000000000000"
```

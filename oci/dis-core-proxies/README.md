# DIS Core Proxies

Deploys the legacy Altinn proxies from the `disproxies/legacy-proxies` OCI artifact.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ENVIRONMENT` | - | Yes | Environment folder inside the artifact; selects `./envs/<ENVIRONMENT>` as the Flux Kustomization path |
| `UPSTREAM_HOSTNAME` | `UPSTREAM-HOSTNAME-NOT-SET.invalid` | Yes | Hostname the proxies forward to in the `legacy-upstream` ConfigMap; used for `proxy_pass`, the `Host` header sent upstream, and TLS SNI (`proxy_ssl_name`) |

## Layers

| Path | Description |
|------|-------------|
| `base` | OCIRepository and Flux Kustomization for `oci://altinncr.azurecr.io/disproxies/legacy-proxies` (tag `main`), in `flux-system`, deploying into `default`, plus the `legacy-upstream` ConfigMap holding `upstream.conf` |
| `multitenancy` | Moves the Flux objects to `platform-system` |

`UPSTREAM_HOSTNAME` is required despite carrying a default. Flux substitutes an
undefined variable with an empty string and has no strict mode, so the default is
an unresolvable `.invalid` sentinel: nginx refuses to load the config, the proxy
pods crashloop, the Flux Kustomization reports NotReady, and the pod log names the
variable that was left unset.

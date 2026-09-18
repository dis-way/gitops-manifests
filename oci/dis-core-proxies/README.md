# DIS Core Proxies

Deploys the legacy Altinn proxies from the `disproxies/legacy-proxies` OCI artifact.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `ENVIRONMENT` | - | Yes | Environment folder inside the artifact; selects `./envs/<ENVIRONMENT>` as the Flux Kustomization path |
| `UPSTREAM_HOSTNAME` | `UPSTREAM-HOSTNAME-NOT-SET.invalid` | Yes | Hostname the proxies forward to (`proxy_pass`, `proxy_ssl_name`) in the `legacy-upstream` ConfigMap |
| `UPSTREAM_HOST_HEADER` | `UPSTREAM-HOST-HEADER-NOT-SET.invalid` | Yes | Value of the `Host` header sent upstream |

## Layers

| Path | Description |
|------|-------------|
| `base` | OCIRepository and Flux Kustomization for `oci://altinncr.azurecr.io/disproxies/legacy-proxies` (tag `main`), in `flux-system`, deploying into `default`, plus the `legacy-upstream` ConfigMap holding `upstream.conf` |
| `multitenancy` | Moves the Flux objects to `platform-system` |

Both upstream variables are required despite carrying a default. Flux substitutes
an undefined variable with an empty string and has no strict mode, so the defaults
are unresolvable `.invalid` sentinels: nginx refuses to load the config, the proxy
pods crashloop, the Flux Kustomization reports NotReady, and the pod log names the
variable that was left unset.

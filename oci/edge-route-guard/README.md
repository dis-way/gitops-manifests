# Edge Route Guard

Deploys a ValidatingAdmissionPolicy that only admits an `HTTPRoute` when every hostname and path it uses is allowed by annotations on the route's namespace.

Annotate each team namespace with `<hostname>/edge-allowed-paths: "/prefix-a,/prefix-b"`. A path is allowed if it equals a prefix or starts with `<prefix>/`; `/` gives the namespace the whole hostname. Routes must set `spec.hostnames`, and every match must use an `Exact` or `PathPrefix` path.

## Variables

None.

## Layers

| Path | Description |
|------|-------------|
| `base` | `ValidatingAdmissionPolicy` and `ValidatingAdmissionPolicyBinding` (cluster-scoped, applies to all namespaces) |
| `edge` | Entry point for the dis-edge clusters; same as `base` |

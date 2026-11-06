# Azure Service Operator

Deploys Azure Service Operator v2 for managing Azure resources via Kubernetes CRDs.

## Variables

| Variable | Default | Required | Description |
|----------|---------|----------|-------------|
| `CRD_PATTERN` | - | Yes | Pattern for which Azure CRDs to install |
| `AZURE_TENANT_ID` | - | Yes | Azure AD tenant ID |
| `AZURE_CLIENT_ID` | - | Yes | Azure AD client ID for workload identity |
| `AZURE_SUBSCRIPTION_ID` | - | Yes | Azure subscription ID |
| `AKS_POD_IPV4_CIDR` | `10.240.0.0/16` | No | Pod network IPv4 CIDR (for policies) |
| `AKS_POD_IPV6_CIDR` | `fd10:59f0:8c79:240::/64` | No | Pod network IPv6 CIDR (for policies) |
| `AKS_VNET_IPV4_CIDR` | - | Yes | AKS VNET IPv4 CIDR (for policies) |
| `AKS_VNET_IPV6_CIDR` | - | Yes | AKS VNET IPv6 CIDR (for policies) |

## Layers

| Path | Description |
|------|-------------|
| `base` | HelmRelease, HelmRepository, and namespace |
| `apps` | Additional application resources |
| `multitenancy` | Multi-tenant configuration and the admission policy below |
| `policies` | Linkerd authorization policies for default-deny inbound |

## Admission policy

`aso-product-writes` guards the ASO objects in `product-*` namespaces. Only the DIS platform operators, ASO itself and the kube-system controllers that delete dependents may create, update or delete them. Cluster admins are admitted too.

- **Why.** ASO runs with one Azure identity for all products. Azure ABAC cannot limit the scope or the principal of a role assignment. A product applies the DIS custom resources instead, and the operators create the ASO objects.
- **Scope.** The API groups in `CRD_PATTERN`. Update the policy and `CRD_PATTERN` together. The policy does not cover the status subresource.
- **Rollout.** The binding runs with `Audit` and `Warn`. The API server admits the request, writes an audit annotation and returns a warning. Look in the `kube-audit-admin` log for `aso-product-writes`. Switch the binding to `Deny` when that log shows no failure from an operator or a controller. Before that, check that no product syncroot applies an ASO object itself. Under `Deny` that apply fails, and Flux marks the whole product Kustomization not ready.
- **Layer.** `multitenancy` only.
- **Break-glass.** A subject that may delete the policy binding is a cluster admin. The policy cannot stop a cluster admin, so it admits them. They can fix a stuck ASO object in a product namespace. A product namespace admin cannot delete a cluster-scoped binding and stays denied.
- **Verification.** `kustomize build multitenancy` renders the policy. The API server compiles the CEL expressions when Flux applies them. The Kyverno CLI can evaluate the subject lists offline, but not the `authorizer` check. The repo has no local test.

## Dependencies

- `cert-manager` must be installed (HelmRelease depends on it)

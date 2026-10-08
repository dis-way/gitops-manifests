# Proposal: update clusters_in_rings.json daily with a workflow

Not implemented yet; written down for discussion.

`clusters_in_rings.json` is a copy of state set elsewhere and drifts when nobody updates it. A daily workflow could rebuild it and open a PR when anything changes. No cluster access is needed: Azure Resource Graph has the Flux configurations of every AKS cluster. A test on 2026-10-08 reproduced the file for every cluster except the dis-edge ones.

```kusto
kubernetesconfigurationresources
| where type =~ 'microsoft.kubernetesconfiguration/fluxconfigurations'
| extend cluster = tostring(split(id, '/')[8]),
         url = tostring(properties.ociRepository.url),
         tag = tostring(properties.ociRepository.repositoryRef.tag)
| where url contains 'manifests/infra/'
| summarize tags = make_set(tag) by cluster
```

The workflow would:

1. Run on a daily cron at an off-hour minute (e.g. `43 5 * * *`) and on `workflow_dispatch`.
2. Run the query above and ignore `latest` tags (some OCI repositories track `latest` and are not part of a ring).
3. Read the dis-edge rings from `flux/clusters/*/` in `dis-way/core`.
4. Put every other AKS cluster (from `resources | where type =~ 'microsoft.containerservice/managedclusters'`) under `untracked`.
5. Fail if a cluster follows more than one ring, rather than pick one.
6. Open a PR when the file changes, committing through the Contents API so GitHub signs it, like `update-cloudflare-ips.yml`.

What it needs:

- **A read-only Azure identity.** An app registration with a federated credential for this repo, and `Reader` on the root management group (or a custom role with only `Microsoft.ContainerService/managedClusters/read` and `Microsoft.KubernetesConfiguration/fluxConfigurations/read`). Resource Graph only returns what the identity can read, and the clusters span many subscriptions. The existing ACR push identity should not be widened for this. Setting this up needs tenant-level rights in Entra ID and Azure.
- **Read access to `dis-way/core`** for the dis-edge rings. `GITHUB_TOKEN` cannot read another repo, so this needs a GitHub App token or a fine-grained PAT. Without it, the dis-edge entries stay hand-maintained.
- **Dropping `verified`**, or changing it only when the content changes. Otherwise every run produces a diff and a PR. Git history records when the file last changed.

Open questions:

- Open a PR, or push straight to `main`? The file is in the repo root, so it does not trigger artifact builds or Release Please.
- Include dis-edge from the start, or begin with the Azure query only?

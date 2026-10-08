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
6. Open a PR when the file changes, committing through the Contents API so GitHub signs it, like `update-cloudflare-ips.yml`. It never pushes to `main` directly.

What it needs:

- **A read-only user-assigned managed identity.** A federated identity credential on the UAMI trusts this repo's workflow, and `azure/login` signs in with the UAMI's client ID. It gets a custom role assigned on the root management group, because Resource Graph only returns what the identity can read and the clusters span many subscriptions. The existing ACR push identity should not be widened for this. Creating the role and assigning it at management-group level needs tenant-level rights in Azure.

  ```json
  {
    "Name": "Flux Ring Reader",
    "Description": "Read AKS clusters and their Flux configurations, for clusters_in_rings.json.",
    "Actions": [
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.KubernetesConfiguration/fluxConfigurations/read"
    ],
    "NotActions": [],
    "DataActions": [],
    "NotDataActions": [],
    "AssignableScopes": ["/providers/Microsoft.Management/managementGroups/<root-mg-id>"]
  }
  ```

  `managedClusters/read` returns cluster properties only. Getting credentials is a separate action (`listClusterUserCredential/action`) that the role does not grant.
- **A GitHub App with read access to `dis-way/core`** for the dis-edge rings. `GITHUB_TOKEN` cannot read another repo. The workflow exchanges the app's credentials for a short-lived installation token with `actions/create-github-app-token`, scoped to `contents: read` on `core`.
- **Dropping `verified`**, or changing it only when the content changes. Otherwise every run produces a diff and a PR. Git history records when the file last changed.

Open questions:

- Include dis-edge from the start, or begin with the Azure query only?

## Alternative: read the ring from a cluster tag

If every AKS cluster carries its ring as an Azure tag, set by our existing tagging, the workflow reads the tags instead of the Flux configurations. Below, `<ring-tag>` stands for the tag name; its values should be the ring names used in `oci/releaseconfig.json` (`at_ring1` … `prod_ring2`).

One query returns every cluster and its ring:

```kusto
resources
| where type =~ 'microsoft.containerservice/managedclusters'
| project name, ring = tostring(tags['<ring-tag>'])
| order by name asc
```

The workflow would:

1. Run on the same schedule and triggers as above.
2. Run the query above.
3. Group the clusters by `ring`. Clusters without the tag go under `untracked`.
4. Fail if a tag value is not one of the six ring names, so a typo does not create a new ring.
5. Open a PR when the file changes, as above.

What changes compared with the Flux configuration approach:

- **The custom role needs only `Microsoft.ContainerService/managedClusters/read`.** Tags are returned as part of the resource. `fluxConfigurations/read` is not needed.
- **No GitHub App.** dis-edge clusters carry the same tag, so the workflow does not read `dis-way/core`.
- **One query covers every cluster**, including dis-edge and the clusters without Flux.

What the tag does not tell us:

- **It is the intended ring, not what the cluster pulls.** It is accurate as long as the tag and the ring are set from the same value. The Flux configuration query above can still be run now and then as a check that they agree.

# ActiveMQ

Deploys ActiveMQ Classic (`activemq-eformidling`) as an external message broker for eFormidling, with a persistent volume for broker data. The broker runs as non-root, and the web console (8161) only accepts loopback clients. The Service does not expose it, so port-forward to the Deployment: `kubectl -n activemq port-forward deploy/activemq-eformidling 8161:8161`.

## Variables

None — all configuration is static in the manifests.

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, StorageClass, PVC, Deployment, and Service |
| `tt02` | Overrides PVC storage to 2Gi |
| `prod` | Overrides PVC storage to 20Gi and increases CPU/memory limits |

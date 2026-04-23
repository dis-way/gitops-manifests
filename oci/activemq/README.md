# ActiveMQ

Deploys ActiveMQ 5.15.9 (`activemq-eformidling`) for eFormidling messaging with a persistent volume for broker data.

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, StorageClass, PVC, Deployment, and Service |
| `staging` | Overrides PVC storage to 2Gi |
| `prod` | Overrides PVC storage to 20Gi and increases CPU/memory limits |

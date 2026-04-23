# ActiveMQ

Deploys ActiveMQ Classic (`activemq-eformidling`) as an external message broker for eFormidling, with a persistent volume for broker data.

## Variables

None — all configuration is static in the manifests.

## Layers

| Path | Description |
|------|-------------|
| `base` | Namespace, StorageClass, PVC, Deployment, and Service |
| `staging` | Overrides PVC storage to 2Gi |
| `prod` | Overrides PVC storage to 20Gi and increases CPU/memory limits |

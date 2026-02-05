# Gateway-API resources files for Traefik
These files are downloaded according to the urls defined [here](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-gateway/#requirements)

Files are downloaded with curl:

```bash
curl -L https://raw.githubusercontent.com/traefik/traefik/v3.6/docs/content/reference/dynamic-configuration/kubernetes-gateway-rbac.yml -o traefik-gateway-rbac.yaml
curl -L https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml -o gateway-api-standard-install.yaml
```

Do not change these manually!

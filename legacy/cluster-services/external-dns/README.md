```
ln -s /path/to/external-dns/secrets.yaml secrets.yaml

helm install --namespace kube-system --name external-dns stable/external-dns -f config.yaml -f secret.yaml
```

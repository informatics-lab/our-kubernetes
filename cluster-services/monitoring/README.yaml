```shell
cp secret.example.yaml secret.yaml
# Replace username and password in secret.yaml with base64 encoded values
kubectl create -f secret.yaml
kubectl create -f config.yaml
kubectl create -f monitoring.yaml
```

```
helm install stable/prometheus --name prometheus --namespace monitoring -f prometheus.yaml
```

# kube2iam
```
ln -s /path/to/kube2iam/secrets.yaml secrets.yaml

helm install --name kube2iam --namespace kube-system -f values.yaml -f secrets.yaml stable/kube2iam
```

```
helm upgrade kube2iam stable/kube2iam -f values.yaml -f secrets.yaml
```

```
helm delete kube2iam --purge
```

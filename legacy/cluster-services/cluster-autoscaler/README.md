```
ln -s /path/to/drone/secrets.yaml secrets.yaml
helm install stable/cluster-autoscaler --name cluster-autoscaler --namespace kube-system -f config.yaml -f secrets.yaml
```

```
helm upgrade cluster-autoscaler stable/cluster-autoscaler -f config.yaml -f secrets.yaml
```

```
helm delete cluster-autoscaler --purge
```

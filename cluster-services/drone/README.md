```
ln -s /path/to/drone/secrets.yaml secrets.yaml
helm install incubator/drone --name drone --namespace drone -f config.yaml -f secrets.yaml
```

```
helm upgrade drone incubator/drone -f config.yaml -f secrets.yaml
```

```
helm delete drone --purge
```

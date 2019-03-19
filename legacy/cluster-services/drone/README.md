```
ln -s /path/to/drone/secrets.yaml secrets.yaml
helm install stable/drone --name drone --namespace drone -f config.yaml -f secrets.yaml
```

```
helm upgrade drone stable/drone -f config.yaml -f secrets.yaml
```

```
helm delete drone --purge
```

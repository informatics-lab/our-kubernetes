```shell
# install
helm install stable/nginx-ingress --name nginx-ingress --namespace kube-system -f config.yaml

# upgrade
helm upgrade nginx-ingress stable/nginx-ingress --namespace kube-system -f config.yaml
```

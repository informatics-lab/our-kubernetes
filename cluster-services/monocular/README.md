```
$ kubectl create ns monocular
$ helm repo add monocular https://helm.github.io/monocular
$ helm install monocular/monocular --name monocular --namespace monocular -f config.yaml
```

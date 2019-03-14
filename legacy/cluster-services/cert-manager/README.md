```shell
# Install the cert-manager CRDs
helm install --namespace kube-system --name cert-manager stable/cert-manager -f config.yaml

# Create a cluster certificate issuer
kubectl -n kube-system create -f cluster-issuer.yaml

# Update the cluster to use the issuer by default
helm upgrade cert-manager stable/cert-manager  --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt,--default-issuer-kind=ClusterIssuer}'
```

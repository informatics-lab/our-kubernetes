# Cert Manager

## New Instructions

```shell
# Add the new helm repo and a cert-manager namespace.
kubectl create ns cert-manager
helm repo add jetstack https://charts.jetstack.io

# Important: you must install the cert-manager CRDs before installing the cert-manager Helm chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# Important: if the cert-manager namespace already exists, you must ensure
# it has an additional label on it in order for the deployment to succeed.
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"

# Install the cert-manager helm chart
$ helm install --name my-release --namespace cert-manager jetstack/cert-manager
```

### Newer Instructions

```shell
# Install the CustomResourceDefinition resources separately
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# Create the namespace for cert-manager
kubectl create namespace cert-manager

# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io

# Update your local Helm chart repository cache
helm repo update

# Install the cert-manager Helm chart
helm install \
  --name cert-manager \
  --namespace cert-manager \
  --version v0.8.1 \
  jetstack/cert-manager
```

## Old Instructions

```shell
# Install the cert-manager CRDs
helm install --namespace kube-system --name cert-manager stable/cert-manager -f config.yaml

# Create a cluster certificate issuer
kubectl -n kube-system create -f cluster-issuer.yaml

# Update the cluster to use the issuer by default
helm upgrade cert-manager stable/cert-manager  --set ingressShim.extraArgs='{--default-issuer-name=letsencrypt,--default-issuer-kind=ClusterIssuer}'
```

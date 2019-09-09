#!/usr/bin/env bash

set -ex

#####
# Update an existing autoscaling Azure Kubernetes Service resource with helm and tiller,
# and specific helm charts.
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --overwrite-existing

# Create dashboard rbac config.
kubectl apply -f ../charts/dashboard_rbac.yaml

# Install and update helm and tiller.
kubectl apply -f ../charts/helm_rbac.yaml
helm init --upgrade --service-account tiller --wait

# Install helm charts to customise the cluster.
helm upgrade --install --namespace kube-system external-dns stable/external-dns \
             -f ../charts/external_dns_config.yaml \
             -f ../charts/azure-secrets.yaml
helm upgrade --install --namespace kube-system nginx-ingress stable/nginx-ingress \
             -f ../charts/nginx-ingress-config.yaml

################
# Cert Manager #
################
#
# The old way of doing things...

# kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
# # ...Label the already-existing namespace.
# kubectl label namespace kube-system certmanager.k8s.io/disable-validation="true" || true
# helm upgrade --install --namespace kube-system cert-manager stable/cert-manager \
#             --set ingressShim.defaultIssuerName=letsencrypt \
#             --set ingressShim.defaultIssuerKind=ClusterIssuer

# And the new.
# See https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html.

# Add the Jetstack Helm repository and update repo list.
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install the CustomResourceDefinition resources separately
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# Create a cert-manager namespace, and label it to disable resource validation.
kubectl create namespace cert-manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# Install the cert-manager helm chart.
helm upgrade --install --namespace cert-manager cert-manager jetstack/cert-manager \
             --version v0.8.1 -f ../charts/cert-manager-config.yaml

# Apply the cluster issuer.
kubectl apply -f ../charts/cluster-issuer.yaml

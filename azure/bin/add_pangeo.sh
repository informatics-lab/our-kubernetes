#!/usr/bin/env bash

set -ex

#####
# Update an existing autoscaling Azure Kubernetes Service resource to add the Informatics Lab pangeo.
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $CLUSTER_GROUP_NAME -n $RESOURCE_NAME --overwrite-existing

# Add upstream pangeo repo and update
helm repo add pangeo https://pangeo-data.github.io/helm-chart/
helm repo update

# Install pangeo.
pushd /Users/DPeterK/gh/our-pangeo

# Get dependencies
helm dependency update jadepangeo
# Install pangeo
helm upgrade --install --namespace=panzure panzure.informaticslab.co.uk jadepangeo -f env/azure/values.yaml -f env/azure/secrets.yaml

popd

# If we wanted to install the upstream pangeo.
# helm upgrade --install --namespace pangeo pangeo pangeo/pangeo -f ../charts/pangeo.yaml

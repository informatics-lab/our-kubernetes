#!/usr/bin/env bash

set -ex

# Create an autoscaling Azure Kubernetes Service resource.

# Global variables.
export RESOURCE_LOCATION="westeurope"
# export RESOURCE_LOCATION="uksouth"
export RESOURCE_NAME="panzure"
export CLUSTER_GROUP_NAME="pangeo-azure-vk"
export STORAGE_ACCT_NAME="pangeoazuresa"
export CONTAINER_NAME="ourpangeo"
export SERVICE_PRINCIPAL_NAME="pangeo-sp-vk"
export ACR_SECRET_NAME="acr-container-auth"
export PANGEO_CONFIG_PATH=""
export ENV="panzure"

# Run the individual elements of the AKS resource setup process.
./create_cluster_master.sh
# ./create_cluster_nodes.sh
# ./create_cluster_storage.sh
# ./add_helm.sh
# ./add_pangeo.sh


# To access the kubernetes dashboard...
# az aks browse -g 1st_wednesday -n as-practice
# az aks browse -g $RESOURCE_GROUP_NAME -n $RESOURCE_NAME

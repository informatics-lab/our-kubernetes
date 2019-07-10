#!/usr/bin/env bash

set -ex

# Create an autoscaling Azure Kubernetes Service resource.

# Global variables.
export RESOURCE_LOCATION="westeurope"
# export RESOURCE_LOCATION="uksouth"
# export RESOURCE_GROUP_NAME="1st_wednesday"
export RESOURCE_NAME="pangeo"
export CLUSTER_GROUP_NAME="our-pangeo-azure"
# export CLUSTER_GROUP_NAME="1st_wednesday"
export CONTAINER_NAME="ourpangeo"
export PANGEO_VER="our-pangeo"
export SERVICE_PRINCIPAL_NAME="our-pangeo-sp"

# Run the individual elements of the AKS resource setup process.
# ./create_cluster_master__no_acr.sh
# ./create_cluster_nodes__no_acr.sh
./create_cluster_master.sh
./create_cluster_nodes.sh
./add_helm.sh
./add_pangeo.sh


# To access the kubernetes dashboard...
# az aks browse -g 1st_wednesday -n as-practice
# az aks browse -g $RESOURCE_GROUP_NAME -n $RESOURCE_NAME

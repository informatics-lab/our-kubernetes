#!/usr/bin/env bash

set -ex

# Create an autoscaling Azure Kubernetes Service resource.

# Global variables.
# export RESOURCE_LOCATION="westeurope"
export RESOURCE_LOCATION="uksouth"
export RESOURCE_NAME="pangeo"  # TODO: change to `panzure`.
export CLUSTER_GROUP_NAME="our-pangeo-azure"
export CONTAINER_NAME="ourpangeo"
export SERVICE_PRINCIPAL_NAME="our-pangeo-sp"
export ENV="panzure"

# Run the individual elements of the AKS resource setup process.
# ./create_cluster_master.sh
# ./create_cluster_nodes.sh
# ./add_helm.sh
./add_pangeo.sh


# To access the kubernetes dashboard...
# az aks browse -g 1st_wednesday -n as-practice
# az aks browse -g $RESOURCE_GROUP_NAME -n $RESOURCE_NAME

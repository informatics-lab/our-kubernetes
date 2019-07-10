#!/usr/bin/env bash

set -ex

#####
# Add nodegroups to the Azure Kubernetes Service resource group.
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $CLUSTER_GROUP_NAME -n $RESOURCE_NAME --overwrite-existing

# Set up standard worker nodes.
az aks nodepool add \
  --resource-group $CLUSTER_GROUP_NAME \
  --cluster-name $RESOURCE_NAME \
  --name "${RESOURCE_NAME}nodes" \
  --node-vm-size Standard_B16ms \
  --enable-cluster-autoscaler \
  --node-count 1 \
  --min-count 1 \
  --max-count 20

# GPU nodes!
# Note that you can't set the count directly to 0.
# Instead, create it with a single node and then immediately scale to 0.
# az aks nodepool add \
#   --resource-group $CLUSTER_GROUP_NAME \
#   --cluster-name $RESOURCE_NAME \
#   --name "${RESOURCE_NAME}gpu" \
#   --node-vm-size Standard_NC6 \
#   --enable-cluster-autoscaler \
#   --node-count 1 \
#   --min-count 1 \
#   --max-count 3


# Check our nodepools.
az aks nodepool list \
  -resource-group $CLUSTER_GROUP_NAME \
  --cluster-name $RESOURCE_NAME \
  -o table

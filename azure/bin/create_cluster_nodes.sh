#!/usr/bin/env bash

set -ex

#####
# Add nodegroups to the Azure Kubernetes Service resource group.
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $RESOURE_GROUP_NAME -n $CLUSTER_NAME --overwrite-existing

# Create nodes for the the AKS cluster in multiple availability zones.
# AZ_MIN=1
# AZ_MAX=3

# for AZ_NUM in `seq $AZ_MIN $AZ_MAX`; do
#     # Set up standard nodes in AZ1-3.
#     az aks nodepool add \
#       --resource-group $RESOURE_GROUP_NAME \
#       --cluster-name $CLUSTER_NAME \
#       --name "${CLUSTER_NAME}n${AZ_NUM}" \
#       --node-zones $AZ_NUM \
#       --node-vm-size Standard_B8ms \
#       --enable-cluster-autoscaler \
#       --node-count 1 \
#       --min-count 1 \
#       --max-count 20
# done

# Set up a standard worker nodepool.
az aks nodepool add \
  --resource-group $RESOURE_GROUP_NAME \
  --cluster-name $CLUSTER_NAME \
  --name "workers" \
  --node-vm-size Standard_B16ms \
  --enable-cluster-autoscaler \
  --node-count 1 \
  --min-count 1 \
  --max-count 20

# GPU nodes!
# az aks nodepool add \
#   --resource-group $RESOURE_GROUP_NAME \
#   --cluster-name $CLUSTER_NAME \
#   --name "${CLUSTER_NAME}GPUs" \
#   --node-vm-size Standard_NC6 \
#   --enable-cluster-autoscaler \
#   --node-count 1 \
#   --min-count 1 \
#   --max-count 3

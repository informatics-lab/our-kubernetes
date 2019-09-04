#!/usr/bin/env bash

set -ex

#####
# Create storage for Pangeo on Azure. This includes a number of elements:
#   * Check for existing storage accounts in the pangeo resource group
#   * Create an azure storage account to logically track all Pangeo storage on Azure, if it doesn't already exist
#   * Apply the `azurefile` Kubernetes storage class config
#   * Apply the azure PVC cluster role config
#   * Create the `/scratch` PVC.
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $RESOURE_GROUP_NAME -n $CLUSTER_NAME --overwrite-existing

# XXX: The storage account needs to be created in the "shadow resource group".
#      See https://github.com/Azure/AKS/issues/91.
SHADOW_RG_NAME="MC_${RESOURE_GROUP_NAME}_${CLUSTER_NAME}_${RESOURCE_LOCATION}"

# Check for an existing azure storage account for Pangeo, and create it if missing.
EXISTING_SA_NAMES=$(az storage account list \
                      --resource-group $SHADOW_RG_NAME \
                      --query "[].name | join(',', @)")

if [[ ! $EXISTING_SA_NAMES =~ $STORAGE_ACCT_NAME ]]; then
    az storage account create \
        --name $STORAGE_ACCT_NAME \
        --resource-group $SHADOW_RG_NAME \
        --location $RESOURCE_LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
fi

# Add file storage class config for user homespaces...
kubectl apply -f ../charts/azure-files-sc.yaml
kubectl apply -f ../charts/azure-pvc-roles.yaml
# ... and for scratch - in the pangeo namespace.
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
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --overwrite-existing


# Create a resource group for the storage if it doesn't already exist
if [ $(az group exists --resource-group ${STORAGE_RESOURCE_GROUP_NAME}) == "false" ]; then
    az group create --name $STORAGE_RESOURCE_GROUP_NAME --location $RESOURCE_LOCATION
fi


# Check for an existing azure storage accounts for current environment and common, and create it if missing.
EXISTING_SA_NAMES=$(az storage account list \
                      --resource-group $STORAGE_RESOURCE_GROUP_NAME \
                      --query "[].name | join(',', @)")

if [[ ! $EXISTING_SA_NAMES =~ $ENV_STORAGE_ACCT_NAME ]]; then
    az storage account create \
        --name $ENV_STORAGE_ACCT_NAME \
        --resource-group $STORAGE_RESOURCE_GROUP_NAME \
        --location $RESOURCE_LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
fi

if [[ ! $EXISTING_SA_NAMES =~ $COMMON_STORAGE_ACCT_NAME ]]; then
    az storage account create \
        --name $COMMON_STORAGE_ACCT_NAME \
        --resource-group $STORAGE_RESOURCE_GROUP_NAME \
        --location $RESOURCE_LOCATION \
        --sku Standard_LRS \
        --kind StorageV2
fi


# Add file storage class config
# Pipe azure-files-sc.yaml through sed to fill in the correct account name
kubectl apply -f ../charts/azure-pvc-roles.yaml
cat  ../charts/azure-files-sc.yaml | \
    sed "s/[$][{]ENV_STORAGE_ACCT_NAME[}]/$ENV_STORAGE_ACCT_NAME/g" |\
    sed "s/[$][{]COMMON_STORAGE_ACCT_NAME[}]/$COMMON_STORAGE_ACCT_NAME/g" |\
    sed "s/[$][{]STORAGE_RESOURCE_GROUP_NAME[}]/$STORAGE_RESOURCE_GROUP_NAME/g" |\
   kubectl apply -f  - 

# https://github.com/MicrosoftDocs/azure-docs/blob/master/articles/aks/azure-disk-volume.md#create-an-azure-disk
# If you instead create the disk in a separate resource group, you must grant the Azure Kubernetes Service (AKS) service principal for your cluster the Contributor role to the disk's resource group.
CLUSTER_SERVICE_PRINCIPAL_NAME=$( az aks show --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP_NAME --query "servicePrincipalProfile.clientId" -o tsv)
CLUSTER_SERVICE_PRINCIPAL_OBJECT_ID=$(az ad sp show --id $CLUSTER_SERVICE_PRINCIPAL_NAME --query "objectId" -o tsv)

for STORAGE_ACCT in $COMMON_STORAGE_ACCT_NAME $ENV_STORAGE_ACCT_NAME
do
    SCOPE=$(az storage account show --name $STORAGE_ACCT --query "id" -o tsv)
    az role assignment create --role "Contributor" \
        --assignee-object-id "$CLUSTER_SERVICE_PRINCIPAL_OBJECT_ID" \
        --assignee-principal-type "ServicePrincipal" \
        --scope "$SCOPE"
done


# Add blob storage flex volume
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.9.yaml

BLOB_FUSE_SECRET_NAME="blobfusecreds"
COMMON_STORAGE_ACCT_KEY=$(az storage account keys list --account-name $COMMON_STORAGE_ACCT_NAME --query "[?permissions == 'Full'] | [0].value" --output tsv)
kubectl create secret generic $BLOB_FUSE_SECRET_NAME -n default --from-literal accountname=$COMMON_STORAGE_ACCT_NAME --from-literal accountkey=$COMMON_STORAGE_ACCT_KEY --type="azure/blobfuse"
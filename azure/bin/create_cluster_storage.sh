#!/usr/bin/env bash

set -ex

#####
# Create storage for Pangeo on Azure. This includes a number of elements:
#   * Check for existing storage accounts in the pangeo resource group
#   * Create an azure storage account to logically track all Pangeo storage on Azure, if it doesn't already exist
#   * Apply the `azurefile` Kubernetes storage class config
#   * Apply the azure PVC cluster role config
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --overwrite-existing
az provider register --namespace Microsoft.NetApp --wait # TODO: not sure if this is needed. Once, never, always...

# Create storage for homespaces if does't exist already.
# Using NetApp File
# Code mostly taken from https://docs.microsoft.com/bs-latn-ba/azure/aks/azure-netapp-files
CLUSTER_NODE_RESOURCE_GROUP=$(az aks show --resource-group $RESOURCE_GROUP_NAME --name $CLUSTER_NAME  --query nodeResourceGroup -o tsv)
STORAGE_POOL_NAME=homespaces
SERVICE_LEVEL="Premium"
STORAGE_ACCOUNT_SIZE=4 #TiB
VOLUME_SIZE_GiB=1000 # GiB
DATA_VOLUME_SIZE_GiB=2000 # GiB

# Storage account
if ! az netappfiles account show -n $STORAGE_ACCT_NAME --resource-group $CLUSTER_NODE_RESOURCE_GROUP >/dev/null 2>&1 ; then
    az netappfiles account create \
        --resource-group $CLUSTER_NODE_RESOURCE_GROUP \
        --location $RESOURCE_LOCATION \
        --account-name $STORAGE_ACCT_NAME
fi

# Storage pool
if ! az netappfiles pool show -n $STORAGE_POOL_NAME  --resource-group $CLUSTER_NODE_RESOURCE_GROUP --account-name $STORAGE_ACCT_NAME >/dev/null 2>&1 ; then
    az netappfiles pool create \
        --resource-group $CLUSTER_NODE_RESOURCE_GROUP \
        --location $RESOURCE_LOCATION \
        --account-name $STORAGE_ACCT_NAME \
        --pool-name $STORAGE_POOL_NAME \
        --size $STORAGE_ACCOUNT_SIZE \
        --service-level $SERVICE_LEVEL
fi

# Delegate a subnet. Create a subnet outside of the K8 subnet range but in the vnet range 
K8_RANGE=$(az network vnet subnet show --name $K8_SUB_NET_NAME --resource-group $RESOURCE_GROUP_NAME --vnet-name $V_NET_NAME --query "addressPrefix" -o tsv)
STORAGE_RANGE=$(echo "$K8_RANGE" | cut -d"/" -f 1 | cut -d"." -f 1,2)".88.0/24"
VNET_ID=$(az network vnet show --resource-group $RESOURCE_GROUP_NAME --name $V_NET_NAME --query "id" -o tsv)
if ! az network vnet subnet show --vnet-name $V_NET_NAME --resource-group $RESOURCE_GROUP_NAME --name  $STORAGE_SUB_NET_NAME >/dev/null 2>&1 ; then
    az network vnet subnet create \
        --resource-group $RESOURCE_GROUP_NAME \
        --vnet-name $V_NET_NAME \
        --name $STORAGE_SUB_NET_NAME \
        --delegations "Microsoft.NetApp/volumes" \
        --address-prefixes $STORAGE_RANGE
fi
SUBNET_ID=$(az network vnet subnet show --resource-group $RESOURCE_GROUP_NAME --vnet-name $V_NET_NAME --name $STORAGE_SUB_NET_NAME --query "id" -o tsv)

# Create volume for homespaces
UNIQUE_FILE_PATH=$(echo $STORAGE_ACCT_NAME"-homespace" | tr -cd '[a-zA-Z0-9]' | cut -c1-70) # Please note that creation token needs to be unique within all ANF Accounts
VOLUME_NAME=$UNIQUE_FILE_PATH
if ! az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP  --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME  --volume-name $VOLUME_NAME  >/dev/null 2>&1 ; then
    az netappfiles volume create \
        --resource-group $CLUSTER_NODE_RESOURCE_GROUP \
        --location $RESOURCE_LOCATION \
        --account-name $STORAGE_ACCT_NAME \
        --pool-name $STORAGE_POOL_NAME \
        --name $VOLUME_NAME \
        --service-level $SERVICE_LEVEL \
        --vnet $VNET_ID \
        --subnet $SUBNET_ID \
        --usage-threshold $VOLUME_SIZE_GiB \
        --creation-token $UNIQUE_FILE_PATH \
        --protocol-types "NFSv3"
fi


# Create volume for data
DATA_UNIQUE_FILE_PATH=$(echo $STORAGE_ACCT_NAME"-data" | tr -cd '[a-zA-Z0-9]' | cut -c1-70) # Please note that creation token needs to be unique within all ANF Accounts
DATA_VOLUME_NAME=$DATA_UNIQUE_FILE_PATH
if ! az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP  --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME  --volume-name $DATA_VOLUME_NAME  >/dev/null 2>&1 ; then
    az netappfiles volume create \
        --resource-group $CLUSTER_NODE_RESOURCE_GROUP \
        --location $RESOURCE_LOCATION \
        --account-name $STORAGE_ACCT_NAME \
        --pool-name $STORAGE_POOL_NAME \
        --name $DATA_VOLUME_NAME \
        --service-level $SERVICE_LEVEL \
        --vnet $VNET_ID \
        --subnet $SUBNET_ID \
        --usage-threshold $DATA_VOLUME_SIZE_GiB \
        --creation-token $DATA_UNIQUE_FILE_PATH \
        --protocol-types "NFSv3"
fi




# create PV for created storage

NFS_HOME_IP=$(az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME --volume-name $VOLUME_NAME --query "mountTargets[0].ipAddress" -o tsv)
NFS_HOME_PATH=$(az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME --volume-name $VOLUME_NAME --query "creationToken" -o tsv)

NFS_DATA_IP=$(az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME --volume-name $DATA_VOLUME_NAME --query "mountTargets[0].ipAddress" -o tsv)
NFS_DATA_PATH=$(az netappfiles volume show --resource-group $CLUSTER_NODE_RESOURCE_GROUP --account-name $STORAGE_ACCT_NAME --pool-name $STORAGE_POOL_NAME --volume-name $DATA_VOLUME_NAME --query "creationToken" -o tsv)


# Pipe netapp-files-pv.yaml through sed to fill in the correct connection detais
if ! kubectl get pv pv-nfs >/dev/null 2>&1 ; then
    cat  ../charts/netapp-files-pv.yaml | \
        sed "s/[$][{]NFS_HOME_IP[}]/$NFS_HOME_IP/g" |\
        sed "s/[$][{]NFS_HOME_PATH[}]/$NFS_HOME_PATH/g" |\
        sed "s/[$][{]CLUSTER_NAME[}]/$CLUSTER_NAME/g" |\
        sed "s/[$][{]NFS_DATA_IP[}]/$NFS_DATA_IP/g" |\
        sed "s/[$][{]NFS_DATA_PATH[}]/$NFS_DATA_PATH/g" |\
    kubectl apply -f  - 
fi

# Add blob storage flex volume
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.9.yaml

BLOB_FUSE_SECRET_NAME="blobfusecreds"
BLOB_STORAGE_ACCT_KEY=$(az storage account keys list --account-name $BLOB_STORAGE_ACCT_NAME --query "[?permissions == 'Full'] | [0].value" --output tsv)
if kubectl -n default get secret $BLOB_FUSE_SECRET_NAME >/dev/null 2>&1  ; then
    kubectl -n default delete secret $BLOB_FUSE_SECRET_NAME
fi
kubectl create secret generic $BLOB_FUSE_SECRET_NAME -n default --from-literal accountname=$BLOB_STORAGE_ACCT_NAME --from-literal accountkey=$BLOB_STORAGE_ACCT_KEY --type="azure/blobfuse"

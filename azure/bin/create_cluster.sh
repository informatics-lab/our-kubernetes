#!/usr/bin/env bash

set -ex

#####
# Create an Azure Kubernetes Service resource group and the cluster master.
#####

# Create a resource group for the cluster if it doesn't already exist
if [ $(az group exists --resource-group ${RESOURCE_GROUP_NAME}) == "false" ]; then
    az group create --name $RESOURCE_GROUP_NAME --location $RESOURCE_LOCATION
fi

# Create a VNet group for the cluster if it doesn't already exist
RNG1="00"$RANDOM
RNG1=$(echo -n $RNG1 | tail -c 2)
RNG2="00"$RANDOM
RNG2=$(echo -n $RNG2 | tail -c 2)
IP_RANGE_BASE="1${RNG1}.${RNG2}.0.0"

if ! az network vnet show --name $V_NET_NAME --resource-group $RESOURCE_GROUP_NAME >/dev/null 2>&1 ; then
  az network vnet create \
      --name $V_NET_NAME \
      --resource-group $RESOURCE_GROUP_NAME \
      --address-prefix "${IP_RANGE_BASE}/16" \
      --subnet-name "${K8_SUB_NET_NAME}" \
      --subnet-prefix "${IP_RANGE_BASE}/24" \
      --location $RESOURCE_LOCATION
fi

# Create the AKS cluster.
DEFAULT_NODEPOOL="default"

SUB_NET_ID=$(az network vnet subnet show --name $K8_SUB_NET_NAME --resource-group $RESOURCE_GROUP_NAME --vnet-name $V_NET_NAME --query "id" -o tsv) 
az aks create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $CLUSTER_NAME \
  --location $RESOURCE_LOCATION \
  --kubernetes-version 1.14.6 \
  --node-vm-size Standard_B16ms \
  --nodepool-name $DEFAULT_NODEPOOL\
  --enable-vmss \
  --node-count 1 \
  --vnet-subnet-id $SUB_NET_ID

az aks nodepool update --cluster-name $CLUSTER_NAME \
                       --name $DEFAULT_NODEPOOL \
                       --resource-group $RESOURCE_GROUP_NAME \
                       --enable-cluster-autoscaler \
                       --max-count 20 \
                       --min-count 1

# # # # #
#
# Troubleshooting
#
# If you encounter:
#    * az: error: unrecognised arguments (when the docs say the arguments do exist)
#      Try updating the azure CLI version (brew update on a mac) - the CLI version might be out of date
#      and the unexpectedly missing commands might show up after the update.
#      See https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos?view=azure-cli-latest#update
#    * Unable to load extension
#      Try reinstalling the extension, especially if you've recently updated the Azure CLI.
#      See https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#install-aks-preview-cli-extension.
#    * Principal ... does not exist in directory ...
#      Here directory is as in active directory. This is often due to a race condition between a new principal
#      being created and first being requested. Wait a few minutes and try again.
#    * Operation failed with status: Bad Request. The credentials in ServicePrincipalProfile were invalid.
#      A login failure has occurred, possibly because you're trying to generate resource in a different region
#      to where your login credentials are set up for (?)
#      Try clearing your login credentials:
#      See https://docs.microsoft.com/en-gb/azure/aks/kubernetes-service-principal#troubleshoot
#      If this doesn't work, check the region you are trying to create a resource in.
#    * Operation failed with status: 'Bad Request'. Details: Preview feature ... not registered.
#      You haven't registered a preview feature that you need in order to run an az command.
#      Register the preview feature to your account to fix this.
#      See: https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#register-multiple-node-pool-feature-provider
#      If it _is_ registered and still doesn't work, you may need to register the feature again
#      (have you recently updated the CLI version?).
#      You may also need to register the provider: 'az provider register -n Microsoft.ContainerService'.
#      This may also be caused by trying to run the command in an unsupported region?
#    * Operations failing randomly
#      May well be due to a race condition with the previous operation finishing. Give it 5min and try again.
#      You may also need to delete infrastructure created by the failing command and run the command again to ensure a clean state.
# # # # #


# # # # #
#
# Steps for a clean start:
#   * az login
#   * Install the AKS preview extension: `az extension add --name aks-preview; az extension update --name aks-preview`
#   * Register azure features: `az feature register --name MultiAgentpoolPreview --namespace Microsoft.ContainerService; az feature register --name VMSSPreview --namespace Microsoft.ContainerService`
#   * Register these as providers: `az provider register -n Microsoft.ContainerService`

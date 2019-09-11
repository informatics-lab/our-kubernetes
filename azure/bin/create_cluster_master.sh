#!/usr/bin/env bash

set -ex

#####
# Create an Azure Kubernetes Service resource group and the cluster master.
#####

# Create a resource group for the cluster if it doesn't already exist
if [ $(az group exists --resource-group ${CLUSTER_GROUP_NAME}) == "false" ]; then
    az group create --name $CLUSTER_GROUP_NAME --location $RESOURCE_LOCATION
fi

# Set up a virtual network for the virtual nodes.
VNET_NAME="panzureVnet"
SUBNET_AKS_NAME="panzureSubnet"
SUBNET_VK_NAME="panzureSubnetVK"

az network vnet create \
    --resource-group $CLUSTER_GROUP_NAME \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/8 \
    --subnet-name $SUBNET_AKS_NAME \
    --subnet-prefix 10.240.0.0/16

# Create additional subnet for the virtual nodes.
az network vnet subnet create \
    --resource-group $CLUSTER_GROUP_NAME \
    --vnet-name $VNET_NAME \
    --name $SUBNET_VK_NAME \
    --address-prefixes 10.241.0.0/16

# Check for a service principal that matches the one we're about to set up,
# and delete it if it exists.
EXISTING_SP_ID=$(az ad sp list \
                  --query "[?servicePrincipalNames[0] == 'http://$SERVICE_PRINCIPAL_NAME'].appId" \
                  --output tsv)

# Create a service principal for the vnet.
SUBSCRIPTION_ID=$(az account list --query "[].id" --output tsv)
CLIENT_SECRET=$(az ad sp create-for-rbac \
                  --name http://$SERVICE_PRINCIPAL_NAME \
                  --role contributor \
                  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$CLUSTER_GROUP_NAME \
                  --query password \
                  --output tsv)
CLIENT_ID=$(az ad sp show \
              --id http://$SERVICE_PRINCIPAL_NAME \
              --query appId \
              --output tsv)
# Wait for service principal to definitely create.
echo "Waiting..."
sleep 120
echo "That will do."

# Get the ID of the vnet.
VNET_ID=$(az network vnet show \
            --resource-group $CLUSTER_GROUP_NAME \
            --name $VNET_NAME \
            --query id \
            --output tsv)

# Create a role assignment to allow other commands to contribute to the vnet.
az role assignment create \
  --assignee $CLIENT_ID \
  --scope $VNET_ID \
  --role Contributor

# Get the ID of the AKS subnet (created with the vnet).
SUBNET_AKS_ID=$(az network vnet subnet show \
                  --resource-group $CLUSTER_GROUP_NAME \
                  --vnet-name $VNET_NAME \
                  --name $SUBNET_AKS_NAME \
                  --query id \
                  --output tsv)

# Create the AKS cluster master.
# Note: remove cluster autoscaler first if everything explodes.
az aks create \
  --resource-group $CLUSTER_GROUP_NAME \
  --name $RESOURCE_NAME \
  --location $RESOURCE_LOCATION \
  --kubernetes-version 1.14.6 \
  --node-vm-size Standard_B8ms \
  --enable-cluster-autoscaler \
  --node-count 1 \
  --min-count 1 \
  --max-count 10 \
  --enable-vmss \
  --network-plugin azure \
  --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id $SUBNET_AKS_ID \
  --service-principal $CLIENT_ID \
  --client-secret $CLIENT_SECRET \
  --generate-ssh-keys

# Enable the virtual nodes add-on.
az aks enable-addons \
    --resource-group $CLUSTER_GROUP_NAME \
    --name $RESOURCE_NAME \
    --addons virtual-node \
    --subnet-name $SUBNET_VK_NAME

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

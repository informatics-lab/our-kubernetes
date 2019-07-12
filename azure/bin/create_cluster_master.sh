#!/usr/bin/env bash

set -ex

#####
# Create an Azure Kubernetes Service resource group and the cluster master.
#####

# Create a service principal for the cluster to interact with other Azure resources.
# NOTE: this typically only lasts for one year.
# SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --skip-assignment)
# # Get `appId` and `password` values from service principal, stripping leading `"` and trailing `",`.
# SERVICE_PRINCIPAL_APPID=$(echo "$SERVICE_PRINCIPAL" | grep -i appid | awk '{ print substr($2, 2, length($2)-3) }')
# SERVICE_PRINCIPAL_PASSWD=$(echo "$SERVICE_PRINCIPAL" | grep -i password | awk '{ print substr($2, 2, length($2)-3) }')
SERVICE_PRINCIPAL_PASSWD=$(az ad sp create-for-rbac \
                              --skip-assignment \
                              --name http://$SERVICE_PRINCIPAL_NAME \
                              --query password \
                              --output tsv)
SERVICE_PRINCIPAL_APPID=$(az ad sp show \
                             --id http://$SERVICE_PRINCIPAL_NAME \
                             --query appId \
                             --output tsv)

# Get the name of the ACR Resource ID we want to allow access to.
ACR_ID=$(az acr show \
           --resource-group $CLUSTER_GROUP_NAME \
           --name $CONTAINER_NAME \
           --query "id" \
           --output tsv)

# Use the service principal to allow container pull from ACR.
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_APPID \
  --scope $ACR_ID \
  --role acrpull

# Create a resource group for the cluster if it doesn't already exist
if [ $(az group exists --resource-group ${CLUSTER_GROUP_NAME}) == "false" ]; then
    az group create --name $CLUSTER_GROUP_NAME --location $RESOURCE_LOCATION
fi

# Create the AKS cluster master.
az aks create \
  --resource-group $CLUSTER_GROUP_NAME \
  --name $RESOURCE_NAME \
  --service-principal $SERVICE_PRINCIPAL_APPID \
  --client-secret $SERVICE_PRINCIPAL_PASSWD \
  --location $RESOURCE_LOCATION \
  --kubernetes-version 1.12.8 \
  --node-vm-size Standard_B8ms \
  --enable-vmss \
  --node-count 1

# Create the ACI connector to connect the cluster to virtual nodes.
az aks install-connector \
  --name $RESOURCE_NAME \
  --resource-group $CLUSTER_GROUP_NAME \
  --connector-name "virtual-nodes-connector"

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
#
# # # # #


# # # # #
#
# Steps for a clean start:
#   * az login
#   * Install the AKS preview extension: `az extension add --name aks-preview; az extension update --name aks-preview`
#   * Register azure features: `az feature register --name MultiAgentpoolPreview --namespace Microsoft.ContainerService; az feature register --name VMSSPreview --namespace Microsoft.ContainerService`
#   * Register these as providers: `az provider register -n Microsoft.ContainerService`

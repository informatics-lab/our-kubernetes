#!/usr/bin/env bash

set -ex

#####
# Create a managed Azure Kubernetes Service and master node.
####
# 
# Create the AKS cluster master.
az aks create \
  --resource-group $CLUSTER_GROUP_NAME \
  --name $RESOURCE_NAME \
  --location $RESOURCE_LOCATION \
  --kubernetes-version 1.12.8 \
  --node-vm-size Standard_B4ms \
  --enable-vmss \
  --node-count 1


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

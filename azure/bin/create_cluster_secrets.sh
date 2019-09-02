#!/usr/bin/env bash

set -e

#####
# Generate azure-specific secrets for pulling the pangeo docker image.
# Can't use Azure AD yet; see
# https://docs.microsoft.com/en-us/azure/aks/virtual-nodes-portal#known-limitations
#####

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $CLUSTER_GROUP_NAME -n $RESOURCE_NAME --overwrite-existing

# Specify a name for the service principal we're going to create.
SP_NAME="pangeo-acr-sp"
RANDOMISER=$(LC_CTYPE=C tr -dc a-zA-Z0-9 < /dev/urandom | fold -w 8 | head -n 1)
SERVICE_PRINCIPAL_NAME="http://$SP_NAME-${RANDOMISER}"
# Get the name of the container we need to connect to.
# XXX: CLI magic ahead! If there's more than one name returned here following commands are likely to fail.
#      You may need to modify this command or just pass the container name in the future.
CONTAINER_NAME=$(az acr list --query "[].name" --output tsv)
echo "Container name: $CONTAINER_NAME"

# Populate the ACR login server and resource id.
ACR_LOGIN_SERVER=$(az acr show --name $CONTAINER_NAME --query loginServer --output tsv)
ACR_REGISTRY_ID=$(az acr show --name $CONTAINER_NAME --query id --output tsv)

# Create acrpull role assignment with a scope of the ACR resource.
# XXX: the name needs to be unique otherwise the command fails.
SP_PASSWD=$(az ad sp create-for-rbac \
              --name $SERVICE_PRINCIPAL_NAME \
              --role acrpull \
              --scopes $ACR_REGISTRY_ID \
              --skip-assignment \
              --query password \
              --output tsv)

# Get the service principal client id.
CLIENT_ID=$(az ad sp show \
              --id $SERVICE_PRINCIPAL_NAME \
              --query appId \
              --output tsv)

# echo "Copy these values and keys into the secrets file..."
# echo "registry: $ACR_REGISTRY_ID"
# echo "username: $CLIENT_ID"
# echo "email: <your email address>"
# echo "password: $SP_PASSWD"

# Create a kubernetes secret for accessing the image in ACR.
kubectl create secret docker-registry "acr-secret" \
  --docker-server $ACR_LOGIN_SERVER \
  --docker-username $CLIENT_ID \
  --docker-password $SP_PASSWD \
  --docker-email "DPeterK@outlook.com"
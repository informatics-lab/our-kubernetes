#!/usr/bin/env bash

set -ex

#####
# Create an Azure Kubernetes Service resource group and the cluster master.
####

# Create a service principal for the cluster to interact with other Azure resources.
# NOTE: this typically only lasts for one year.
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

# Create a resource group for the cluster.
# az group create --name $CLUSTER_GROUP_NAME --location $RESOURCE_LOCATION

# Create the AKS cluster master.
az aks create \
  --resource-group $CLUSTER_GROUP_NAME \
  --name $RESOURCE_NAME \
  --service-principal $SERVICE_PRINCIPAL_APPID \
  --client-secret $SERVICE_PRINCIPAL_PASSWD \
  --location $RESOURCE_LOCATION \
  --kubernetes-version 1.12.8 \
  --node-vm-size Standard_B4ms \
  --enable-vmss \
  --node-count 1

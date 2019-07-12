#!/usr/bin/env bash

set -e

#####
# Generate azure-specific secrets for the pangeo helm chart.
# Can't use Azure AD yet; see
# https://docs.microsoft.com/en-us/azure/aks/virtual-nodes-portal#known-limitations
#####

# Parse command-line arguments.
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo "$package - Generate azure-specific secrets for the pangeo helm chart."
            echo " "
            echo "$package [options] application [arguments]"
            echo " "
            echo "options:"
            echo "-h, --help                    show this help and exit"
            echo "-g, --resource-group=NAME     resource group name"
            echo "-n, --name=NAME               cluster name"
            exit 0
            ;;
        -g)
            shift
            if test $# -gt 0; then
                CLUSTER_GROUP_NAME=$1
            else
                echo "no cluster group name specified"
                exit 1
            fi
            shift
            ;;
        --resource-group*)
            CLUSTER_GROUP_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -n)
            shift
            if test $# -gt 0; then
                RESOURCE_NAME=$1
            else
                echo "no cluster group name specified"
                exit 1
            fi
            shift
            ;;
        --name*)
            RESOURCE_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Get kubernetes credentials for AKS resource.
az aks get-credentials -g $CLUSTER_GROUP_NAME -n $RESOURCE_NAME --overwrite-existing

# Specify a name for the service principal we're going to create.
SP_NAME="pangeo-acr-sp"
RANDOMISER=$(LC_CTYPE=C tr -dc a-zA-Z0-9 < /dev/urandom | fold -w 8 | head -n 1)
SERVICE_PRINCIPAL_NAME="http://$SERVICE_PRINCIPAL_NAME-${RANDOMISER}"
# Get the name of the container we need to connect to.
# XXX: CLI magic ahead! If there's more than one name returned here following commands are likely to fail.
#      You may need to modify this command or just pass the container name in the future.
CONTAINER_NAME=$(az acr list --query "[].name" --output tsv)
echo "Container name: $CONTAINER_NAME\n"

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

echo "Copy these values and keys into the secrets file..."
echo "registry: $ACR_REGISTRY_ID"
echo "username: $CLIENT_ID"
echo "email: <your email address>"
echo "password: $SP_PASSWD"

# Create a kubernetes secret for accessing the image in ACR.
# kubectl create secret docker-registry $ACR_SECRET_NAME \
#   --docker-server $ACR_LOGIN_SERVER \
#   --docker-username $CLIENT_ID \
#   --docker-password $SP_PASSWD \
#   --docker-email "DPeterK@outlook.com"


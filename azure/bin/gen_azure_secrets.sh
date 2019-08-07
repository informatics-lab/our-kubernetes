#!/usr/bin/env bash

set -e

#####
# Generate azure-specific secrets for pulling the pangeo docker image.
# Can't use Azure AD yet; see
# https://docs.microsoft.com/en-us/azure/aks/virtual-nodes-portal#known-limitations
#####

# Parse command-line arguments.
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            echo "$package - Generate azure-specific secrets for pulling the Informatics Lab pangeo docker image."
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
                export CLUSTER_GROUP_NAME=$1
            else
                echo "no cluster group name specified"
                exit 1
            fi
            shift
            ;;
        --resource-group*)
            export CLUSTER_GROUP_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        -n)
            shift
            if test $# -gt 0; then
                export RESOURCE_NAME=$1
            else
                echo "no cluster group name specified"
                exit 1
            fi
            shift
            ;;
        --name*)
            export RESOURCE_NAME=`echo $1 | sed -e 's/^[^=]*=//g'`
            shift
            ;;
        *)
            break
            ;;
    esac
done

./create_cluster_secrets.sh
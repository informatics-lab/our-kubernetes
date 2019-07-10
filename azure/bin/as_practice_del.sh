#!/usr/bin/env bash

set -ex

# Delete an autoscaling Azure Kubernetes Service resource.

# Global variables.
RESOURCE_GROUP_NAME="1st_wednesday"
RESOURCE_NAME="as-practice"


CHART_NAMES=$(helm list | grep -iv name | awk '{ print $1 }')
echo $CHART_NAMES

for CHART_NAME in $CHART_NAMES; do
    helm delete --purge $CHART_NAME
done

az aks delete -g $RESOURCE_GROUP_NAME -n $RESOURCE_NAME -y

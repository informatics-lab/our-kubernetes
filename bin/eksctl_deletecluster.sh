#!/usr/bin/env bash

# Script to delete the EKS Cluster.

set -e
source "functions.sh"
# Call the `assume_role` function from `functions.sh`.
assume_role

# Verbosity *after* assuming AWS role.
set -x

# Get the names of things to be deleted.
CLUSTER_NAME=$(eksctl get cluster | grep -iv name | awk '{ print $1 }')
CUSTOMISATION_STACK_NAME="$CLUSTER_NAME-customisations"

# Get kubeconfig for cluster.
eksctl utils write-kubeconfig --name $CLUSTER_NAME --region $AWS_DEFAULT_REGION

# List all helm charts and delete them one by one.
CHART_NAMES=$(helm list | grep -iv name | awk '{ print $1 }')
echo $CHART_NAMES

for CHART_NAME in $CHART_NAMES; do
    helm delete --purge $CHART_NAME
done

# Delete the EFS stack.
aws cloudformation delete-stack --stack-name $CUSTOMISATION_STACK_NAME

# Sleep until cloudformation done...
aws cloudformation wait stack-delete-complete --stack-name $CUSTOMISATION_STACK_NAME

# Delete the EKS stacks created with eksctl.
eksctl delete cluster --name $CLUSTER_NAME

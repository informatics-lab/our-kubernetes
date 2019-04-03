#!/usr/bin/env bash

## Tests
set -e
source "bin/functions.sh"

# Assume the our-kubernetes service manager role.
assume_role

# List cluster
eksctl get cluster

# List nodegroups
eksctl get ng --cluster=$(eksctl get cluster | grep -iv name | grep -iv no | awk '{ print $1 }' | head -n 1)

# Check all pods are running.
ALL_PODS=$(kubectl get pods --all-namespaces | grep -iv namespace)
N_TOTAL_PODS=$(echo $ALL_PODS | wc -l)
N_RUNNING_PODS=$(echo $ALL_PODS | grep -i running | wc -l)

echo "Total number of pods: $N_TOTAL_PODS"
echo "Total number of running pods: $N_RUNNING_PODS"

if [ $N_TOTAL_PODS -ne $N_RUNNING_PODS ]; then
    echo "Not all pods are running!"
    exit 1
fi

# Done!
echo "### We gone tested yo' thing, sir. ###"

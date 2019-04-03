#!/usr/bin/env bash

## Tests
set -e
source "bin/functions.sh"

# Assume the our-kubernetes service manager role.
assume_role

# List cluster
eksctl get cluster

# List nodegroups
eksctl get ng

# Done!
echo "### We gone tested yo' thing, sir. ###"

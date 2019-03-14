#!/usr/bin/env bash

## Tests
set -ex

# Assume the our-kubernetes service manager role.
ROLE_CREDS=$(aws sts assume-role --role-arn "arn:aws:iam::536099501702:role/ourKubernetesServiceManager" \
                                 --role-session-name "our-kubernetes-creation")
# Set environment variables based on the assumed role.
export AWS_ACCESS_KEY_ID=$(echo $ROLE_CREDS | jq .Credentials.AccessKeyId | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_CREDS | jq .Credentials.SecretAccessKey | xargs)
export AWS_SESSION_TOKEN=$(echo $ROLE_CREDS | jq .Credentials.SessionToken | xargs)

# List cluster
eksctl get cluster

# Done!
echo "### We gone tested yo' thing, sir. ###"

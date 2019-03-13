# Script to delete the Pangeo EKS Cluster.

set -e

# Get the names of things to be deleted.
CLUSTER_NAME=$(eksctl get cluster | grep -iv name | awk '{ print $1 }')
CUSTOMISATION_STACK_NAME="eksctl-$CLUSTER_NAME-customisations"

# Delete the loadbalancer set up by nginx-ingress.
helm delete --purge nginx-ingress

# Delete other helm charts.

# [Placeholder for spot integration (?)]
# [Placeholder for dashboard service]
helm delete --purge cluster-autoscaler
# [Placeholder for Prometheus/Grafana]
# [Placeholder for cloudwatch]
helm delete --purge cert-manager
helm delete --purge external-dns
helm delete --purge kube2iam
helm delete --purge nginx-ingress
helm delete --purge s3-fuse-deployer
helm delete --purge efs-provisioner

# Delete the EFS stack.
aws cloudformation delete-stack --stack-name $CUSTOMISATION_STACK_NAME

# Sleep until cloudformation done...
aws cloudformation wait stack-delete-complete --stack-name $CUSTOMISATION_STACK_NAME

# Delete the EKS stacks created with eksctl.
eksctl delete cluster --name $CLUSTER_NAME

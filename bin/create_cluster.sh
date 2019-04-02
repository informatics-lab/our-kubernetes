#!/usr/bin/env bash

# TODO: add testing.

set -e

# Call the `assume_role` function from `functions.sh`.
source "$PWD/functions.sh"
assume_role

# Verbosity *after* assuming AWS role.
set -x

# Set name for cluster.
CLUSTER_NAME="our-kubernetes"

# Check if the cluster already exists before creating a new one.
EXISTING_CLUSTER_NAME=$(eksctl get cluster | grep -iv name | grep -iv no | awk '{ print $1 }' | head -n 1)
echo $EXISTING_CLUSTER_NAME

# TODO: inherit the number of existing nodes.

# If `CLUSTER_NAME` does not match EXISTING_CLUSTER_NAME then we need to create a cluster.
if [[ $CLUSTER_NAME != ${EXISTING_CLUSTER_NAME} ]]; then
    # Create cluster without any nodegroups.
    eksctl create cluster -f $PWD/../chart-configs/eksctl_config.yaml
    # In the future a cluster can be initially created without nodegroups.
    # eksctl create cluster -f eksctl_config.yaml --without-nodegroups

    # Get the name of the newly-created cluster and nodegroups.
    CLUSTER_NAME=$(eksctl get cluster | grep -iv name | grep -iv no | awk '{ print $1 }' | head -n 1)
    echo $CLUSTER_NAME

    NG_NAMES=$(eksctl get ng --cluster=$CLUSTER_NAME | grep -v CLUSTER | awk '{ print $2 }')
    NG_ONDEMAND_NAME=$(echo "$NG_NAMES" | grep ondemand)
    echo $NG_NAMES
    echo $NG_ONDEMAND_NAME

    # Remove the default (Amazon) network driver and install the weave network driver.
    kubectl delete ds aws-node -n kube-system
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

    # Scale the ondemand workers cluster using eksctl.
    eksctl scale nodegroup --cluster=$CLUSTER_NAME --nodes=1 $NG_ONDEMAND_NAME
else
    NG_NAMES=$(eksctl get ng --cluster=$CLUSTER_NAME | grep -v CLUSTER | awk '{ print $2 }')
    NG_ONDEMAND_NAME=$(echo "$NG_NAMES" | grep ondemand)
    echo $NG_NAMES
    echo $NG_ONDEMAND_NAME

    # Get kubeconfig for cluster.
    eksctl utils write-kubeconfig --name $CLUSTER_NAME --region $AWS_DEFAULT_REGION
fi

# Now create the nodegroups. (For the future...)
# eksctl create ng -f eksctl_config.yaml

# Get names as variables.
CLUSTER_STACK_NAME="eksctl-$CLUSTER_NAME-cluster"
CUSTOMISATION_STACK_NAME="$CLUSTER_NAME-customisations"
NG_STACK_NAME="eksctl-$CLUSTER_NAME-nodegroup-$NG_ONDEMAND_NAME"

# Create (or update) a customisation stack using cloudformation.
# (NOTE: this command will always fail if the stack doesn't exist or doesn't need updating
#        (this is what we're testing for, so don't exit on this command failing.)
set +e
if aws cloudformation describe-stacks --stack-name $CUSTOMISATION_STACK_NAME; then
    CLO_CMD=update-stack
else
    CLO_CMD=create-stack
fi

aws cloudformation $CLO_CMD --stack-name $CUSTOMISATION_STACK_NAME \
    --template-body file://$PWD/../chart-configs/eks_stack_customisation.cfyaml \
    --capabilities CAPABILITY_IAM \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameters ParameterKey=EKSClusterStackName,ParameterValue=$CLUSTER_STACK_NAME \
                 ParameterKey=EKSDefaultNodegroupStackName,ParameterValue=$NG_STACK_NAME
set -e

# Sleep until cloudformation done...
aws cloudformation wait stack-create-complete --stack-name $CUSTOMISATION_STACK_NAME
# ... and get the fs name from the cloudformation description, stripping leading and trailing `"` chars.
EFS_RESOURCE_ID=$(aws cloudformation describe-stack-resources --stack-name $CUSTOMISATION_STACK_NAME | jq ".StackResources[].PhysicalResourceId" | grep "fs-" | sed 's/^"\(.*\)"$/\1/')
echo $EFS_RESOURCE_ID

# Now add helm and tiller (as a cluster-admin service).
kubectl apply -f $PWD/../chart-configs/rbac-config.yaml
helm init --upgrade --service-account tiller --wait

# Now install all of the things (helm charts)...
helm repo update

# Install EFS provisioner.
helm upgrade --install --namespace kube-system efs-provisioner stable/efs-provisioner \
     --set efsProvisioner.efsFileSystemId=$EFS_RESOURCE_ID \
     --set efsProvisioner.awsRegion=eu-west-2 # \

# Change the default storageClass (for now, given there's a bug in efs provisioner, this needs to be two steps).
kubectl patch storageclass gp2 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}' || true
kubectl patch storageclass efs -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}' || true

# Add chart repos.
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add informaticslab https://charts.informaticslab.co.uk/
helm repo update

# Install fuse driver.
helm upgrade --install --namespace kube-system s3-fuse-deployer informaticslab/s3-fuse-flex-volume # -f ...

# Remove temp dir only if it exists...
[ -z ${FUSE_TMP_DIR+filler_str} ] || rm -rf $FUSE_TMP_DIR

# Add nginx ingress. (https://kubernetes.github.io/ingress-nginx/)
helm upgrade --install --namespace kube-system nginx-ingress stable/nginx-ingress -f $PWD/../legacy/cluster-services/nginx-ingress/config.yaml

# Install Kube2IAM. (This is a prerequisite for fluentd cloudwatch.)
helm upgrade --install --namespace kube-system kube2iam stable/kube2iam -f $PWD/../chart-configs/kube2iam.yaml

# Set up external DNS.
helm upgrade --install --namespace kube-system external-dns stable/external-dns -f $PWD/../chart-configs/external_dns_config.yaml

# Install Certificate Manager.
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.6/deploy/manifests/00-crds.yaml
# ...Label the already-existing namespace.
kubectl label namespace kube-system certmanager.k8s.io/disable-validation="true" || true
helm upgrade --install --namespace kube-system cert-manager stable/cert-manager \
             --set ingressShim.defaultIssuerName=letsencrypt \
             --set ingressShim.defaultIssuerKind=ClusterIssuer

# Install cloudwatch logs.
# (fluentd cloudwatch? - https://github.com/helm/charts/tree/master/incubator/fluentd-cloudwatch)
helm upgrade --install --namespace kube-system cloudwatch-log-forwarder incubator/fluentd-cloudwatch -f $PWD/../chart-configs/cloudwatch.yaml


# Install Prometheus / Grafana.




# Install GPU Driver.
# kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v1.11/nvidia-device-plugin.yml

# Install autoscaler driver.
helm upgrade --install --namespace kube-system cluster-autoscaler stable/cluster-autoscaler \
             --set autoDiscovery.clusterName=$CLUSTER_NAME \
             -f $PWD/../legacy/cluster-services/cluster-autoscaler/config.yaml

# Install dashboard service.



# Add spot integration.

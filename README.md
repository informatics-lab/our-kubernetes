## Create the cluster

```shell
# Run the terraform
terraform apply terraform

# Export AWS Environment vars
export AWS_ACCESS_KEY_ID=$(terraform output k8s-access-key-id)
export AWS_SECRET_ACCESS_KEY=$(terraform output k8s-secret-access-key)

# Export kops vars
export NAME=testcluster.k8s.informaticslab.co.uk
export KOPS_STATE_STORE="s3://$(terraform output k8s-state-bucket)"

# Create cluster config
kops create cluster --cloud aws --zones eu-west-2a ${NAME}

# Check config
kops edit cluster ${NAME}

```

## Configure dashboard ui

```shell
kubectl create -f https://git.io/kube-dashboard
```

View the dashboard by running `kubectl proxy` and then visiting http://localhost:8001/ui.

## Configure ingress

```shell
kubectl create -f ./cluster-services/nginx-ingress-controller.yaml
```

### Add Lets Encrypt SSL to ingress

```shell
kubectl create -f ./cluster-services/kube-lego.yaml
```

### Create ingress DNS entry

- Locate the ELB which has been created by the ingress controller.
- Copy the DNS name of the ELB.
- Create a DNS entry for ingress which aliases that ELB.

All new services can then alias or CNAME the ingress DNS.

## Configure autoscaling

```shell
kubectl apply -f ./cluster-services/cluster-autoscaler.yml
```

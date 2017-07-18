# Kubernetes Terraform

* [Requirements](#requirements)
* [Create the cluster](#create-the-cluster)
   * [Create required infrastructure](#create-required-infrastructure)
   * [Create the kubernetes components](#create-the-kubernetes-components)
   * [Configure dashboard ui](#configure-dashboard-ui)
   * [Configure ingress](#configure-ingress)
      * [Add Lets Encrypt SSL to ingress](#add-lets-encrypt-ssl-to-ingress)
      * [Create ingress DNS entry](#create-ingress-dns-entry)
   * [Configure autoscaling](#configure-autoscaling)
* [Connect to an existing cluster](#connect-to-an-existing-cluster)

## Requirements

```shell
brew install kops terraform
```

## Create the cluster

### Create required infrastructure

```shell
# Run the terraform
terraform apply terraform
```

### Create the kubernetes components

```shell

# Export AWS Environment vars
export AWS_ACCESS_KEY_ID=$(terraform output k8s-access-key-id)
export AWS_SECRET_ACCESS_KEY=$(terraform output k8s-secret-access-key)

# Export kops vars (you should probably add these to your .bashrc/.zshrc)
export KOPS_CLUSTER_NAME="cluster.$(terraform output k8s-dns-zone)"
export KOPS_STATE_STORE="s3://$(terraform output k8s-state-bucket)"

# Create cluster config
kops create cluster --cloud aws --zones eu-west-2a ${KOPS_CLUSTER_NAME}

# Check config
kops edit cluster ${KOPS_CLUSTER_NAME}

```

### Configure dashboard ui

```shell
kubectl create -f https://git.io/kube-dashboard
```

View the dashboard by running `kubectl proxy` and then visiting http://localhost:8001/ui.

### Configure ingress

```shell
kubectl create -f ./cluster-services/nginx-ingress-controller.yaml
```

#### Add Lets Encrypt SSL to ingress

```shell
kubectl create -f ./cluster-services/kube-lego.yaml
```

#### Create ingress DNS entry

- Locate the ELB which has been created by the ingress controller.
- Copy the DNS name of the ELB.
- Create a DNS entry for ingress which aliases that ELB.

All new services can then alias or CNAME the ingress DNS.

### Configure autoscaling

```shell
kubectl apply -f ./cluster-services/cluster-autoscaler.yml
```

## Connect to an existing cluster

If a cluster already exists you can retrieve the `kubectl` config by setting the `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` vars and then running the following command.

```shell
kops export kubecfg --name ${KOPS_CLUSTER_NAME}
```

You should then be able to use `kubectl`. For example you can list the namespaces.

```shell
kubectl get ns
```

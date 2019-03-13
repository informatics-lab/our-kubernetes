# Our Kubernetes

* [Requirements](#requirements)
* [Create the cluster](#create-the-cluster)
   * [Create required infrastructure with terraform](#create-required-infrastructure)
   * [Create the kubernetes components with kops](#create-the-kubernetes-components)
   * [Configure dashboard ui](#configure-dashboard-ui)
   * [Configure ingress](#configure-ingress)
      * [Add Lets Encrypt SSL to ingress](#add-lets-encrypt-ssl-to-ingress)
      * [Create ingress DNS entry](#create-ingress-dns-entry)
   * [Configure autoscaling](#configure-autoscaling)
* [Connect to an existing cluster](#connect-to-an-existing-cluster)

## Requirements

```shell
brew install kops terraform kubernetes-helm kubectl
```

## Create the cluster

### Create required infrastructure with terraform

To create a kubernetes cluster with kops you need a few bits of infrastructure already in place. This includes an IAM user for kops to use, a DNS zone for routing, an S3 bucket to store config, etc. This can be created simply using the terraform scripts.

```shell
# Run the terraform
terraform apply terraform
```

### Create the kubernetes components with kops

Now we can create the cluster itself.

```shell
# Export AWS Environment vars
export AWS_ACCESS_KEY_ID=$(terraform output k8s-access-key-id)
export AWS_SECRET_ACCESS_KEY=$(terraform output k8s-secret-access-key)

# Export kops vars
# _you should probably add these to your .bashrc/.zshrc but you might want to
# hard code the values rather than pointing to the terraform output_
export KOPS_CLUSTER_NAME="cluster.$(terraform output k8s-dns-zone)"
export KOPS_STATE_STORE="s3://$(terraform output k8s-state-bucket)"

# Generate the cluster config (this gets stored in the S3 bucket)
kops create cluster --cloud aws --zones eu-west-2a ${KOPS_CLUSTER_NAME}

# Check config and make any modifications to the scaling groups etc
kops edit cluster ${KOPS_CLUSTER_NAME}

# Start the cluster, a kops update ensures the AWS infrastructure matches the config
kops update cluster ${KOPS_CLUSTER_NAME} --yes
```


### Create cluster services

Go through each of the services in `cluster-services` and install as per the `README.md` there.

### Create pod disruption budgets

Install the pod disruption budgets as per `pod-disruption-budgets/README.md`.

## Connect to an existing cluster

If a cluster already exists you can retrieve the `kubectl` config by setting the `KOPS_CLUSTER_NAME` and `KOPS_STATE_STORE` vars and then running the following command.

```shell
export KOPS_CLUSTER_NAME="cluster.k8s.informaticslab.co.uk"
export KOPS_STATE_STORE="s3://informticslab-k8s-config"
kops export kubecfg --name ${KOPS_CLUSTER_NAME}
```

You should then be able to use `kubectl`. For example you can list the namespaces.

```shell
kubectl get ns
```

# Kubernetes Terraform

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
brew install kops terraform
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

### Configure dashboard ui

The basic kubernetes cluster doesn't come with the dashboard already installed so let's add it.

```shell
kubectl create -f https://git.io/kube-dashboard
```

View the dashboard by running `kubectl proxy` and then visiting http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/.

### Configure ingress

We also probably want to be able to route traffic into the cluster. This ingress controller will create an ELB which will route traffic to an nginx reverse proxy running on the cluster. You can add new services to the reverse proxy using kubernetes ingress.

```shell
kubectl create -f ./cluster-services/nginx-ingress/config.yaml
kubectl create -f ./cluster-services/nginx-ingress/ingress.yaml
kubectl create -f ./cluster-services/nginx-ingress/services.yaml
```

#### Create ingress DNS entry

Once you've run this you may want to create a domain alias for the ELB which gets created. Perhaps something like `ingress.k8s.informaticslab.co.uk`. This way when you add new services you can simply CNAME the new address to that one, which will cause the traffic to be routed to the ELB and ultimately the nginx reverse proxy.

#### Add Lets Encrypt SSL to ingress

We can also have Lets Encrypt automatically generate SSL certificates for any domain which we add as an ingress. We simply run the `kube-lego` service and it will create a new secret containing the keys when you add a new ingress. Just be sure to create the DNS CNAME and point it to the ingress address before created the ingress in kubernetes otherwise the certificate generation may fail.

```shell
kubectl create -f ./cluster-services/kube-lego.yaml
```

### Configure autoscaling

By default this cluster will not scale automatically despite kops creating the nodes in an autoscaling group. This is because you have the flexibility to create your own scaling policies such as cloudwatch alarms. We are going to use the `cluster-autoscaler` services which checks to see if there are any pods which cannot be scheduled because there is nowhere to put them, if so it scaled up the cluster. It also checks to see if there are nodes which are being under utilised and will remove them after a 10 minute period.

```shell
kubectl apply -f ./cluster-services/cluster-autoscaler.yml
```

### Configure telemetry and monitoring

We also want to have a telegraf agent running on each node sending telemetry to our central monitoring service.

```shell
cp ./cluster-services/monitoring/secret.example.yaml ./cluster-services/monitoring/secret.yaml
# Replace username and password in secret.yaml with base64 encoded values
kubectl create -f ./cluster-services/monitoring/secret.yaml
kubectl create configmap telegraf-config --from-file=./cluster-services/monitoring/telegraf.conf  --namespace=kube-system
kubectl create -f ./cluster-services/monitoring/monitoring.yaml
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

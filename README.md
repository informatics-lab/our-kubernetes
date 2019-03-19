# Our Kubernetes

Functionality to construct and tear down the Informatics Lab kubernetes cluster.

## Requirements

If running locally, you need the following packages installed:

* The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html), [properly configured](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
* [eksctl](https://eksctl.io)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/docs/using_helm/#installing-helm)
* [jq](https://stedolan.github.io/jq/)

## Operation

You can run the cluster creation operation locally:

```shell
./bin/eksctl_createcluster_config.sh
```

This will create an EKS cluster with EFS storage in your AWS account, assuming
you have valid permissions to do so.

### DevOps

PRs merged to this repository will trigger a build of the kubernetes cluster.
Releasing this repository will trigger an update of the kubernetes cluster.

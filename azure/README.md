## some tips

* Install the azure cli - https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
* Follow the ["before you begin"](https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools#before-you-begin)

## prep
Link in the secrets
`ln -s ../private-config/external-dns/azure-secrets.yaml azure/charts/azure-secrets.yaml`


## Install from scratch:

Work in the `bin` dir:

`cd bin`

Install from scratch
`./azure_k8_setup -a -r <resource_group/cluster name>`

e.g.

dev: `./azure_k8_setup -a -r panzure-dev`
prod: `./azure_k8_setup -a -r panzure`



## Delete it all:

`./delete_cluster.sh <resource_group/cluster name>` e.g. `./delete_cluster.sh panzure-dev`

## Update

Prob best to delete and install again from scratch.

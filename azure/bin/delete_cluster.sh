if [ -z "$1" ]
  then
    echo "First argument is required and is name of the resource-group / cluster to delete."
    exit 1
fi

az group deployment list $1 --query '[].name'
echo "This will delete the resource group '$1' including the above deplotments.""
az group delete --name $1
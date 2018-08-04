# Pod disruption budgets

Many helm charts come without pod disruption budgets. There are required for the autoscaler to know how many pods it can have out of commission at once when reshuffling the cluster.

In this directory are some manual PDBs to apply to existing setups.

```
kubectl apply -f .
```

# AWS Spot Instance Termination Handler

Drain nodes and alert in Slack when spot instances are removed.

```
ln -s /path/to/kube-spot-termination-notice-handler/secrets.yaml secrets.yaml

helm install --name kube-spot-termination-notice-handler --namespace kube-system -f values.yaml -f secrets.yaml incubator/kube-spot-termination-notice-handler
```

```
helm upgrade kube-spot-termination-notice-handler incubator/kube-spot-termination-notice-handler -f values.yaml -f secrets.yaml
```

```
helm delete kube-spot-termination-notice-handler --purge
```

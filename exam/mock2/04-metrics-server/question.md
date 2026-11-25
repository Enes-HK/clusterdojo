---
title: kubectl top doesn't work
host: dojo2
setup: last
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/ | Resource metrics pipeline ; https://github.com/kubernetes-sigs/metrics-server#configuration | metrics-server configuration
---
> Target: 6 minutes

`kubectl top` stopped working on this cluster. metrics-server runs as Deployment `metrics-server` in Namespace `kube-system`.

1. Repair metrics-server so that `kubectl top nodes` and `kubectl top pods` work again. The kubelets of this cluster use self-signed serving certificates, and that's fine here.
2. Write the name of the Pod in Namespace `analytics` that uses the most memory into `/home/student/answers/m2-04/top-pod`.

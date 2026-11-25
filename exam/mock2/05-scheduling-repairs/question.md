---
title: Tolerations, a missing scheduler and a waiting Pod
host: dojo2
docs: https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/ | Taints and Tolerations ; https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/ | Assigning Pods to Nodes ; https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/ | Multiple schedulers
---
> Target: 7 minutes

All of this happens in Namespace `platform`.

1. Deployment `agent` must keep running on a node for `300` seconds after that node gets the taint `maintenance=planned:NoExecute`, instead of being evicted right away. Don't taint any node
2. Pod `batch-runner` has been `Pending` since it was created and shows **no events** at all. Find out why and fix it so it runs. Keep its name, image and command
3. Deployment `waiting` has been `Pending` since it was created. Find out why and fix the Deployment. Don't change any node. `drive` is meant to select the node's real disk label

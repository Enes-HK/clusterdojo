---
title: Take a node out for maintenance
host: dojo1
docs: https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/ | Safely Drain a Node ; https://kubernetes.io/docs/tasks/run-application/configure-pdb/ | Specifying a Disruption Budget
---
> Target: 7 minutes

Node `dojo1-worker2` needs maintenance. Drain it.

- The team that owns Deployment `stock-api` in Namespace `warehouse` requires at least **2** of its Pods to stay available during any voluntary disruption. Their PodDisruptionBudget `stock-api` is supposed to enforce that, and it must keep doing so after the drain.
- Pod `legacy-report` in `warehouse` isn't managed by any controller. It must be running again after the drain, unchanged, on another node.

At the end `dojo1-worker2` must be unschedulable and run no Pods other than DaemonSet Pods, and `stock-api` must have 3 ready Pods.

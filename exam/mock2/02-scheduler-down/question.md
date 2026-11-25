---
title: New Pods never start
host: dojo4
setup: last
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/ | Troubleshooting Clusters ; https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/ | kube-scheduler
---
> Target: 5 minutes

On this cluster, every Pod created in the last few minutes is stuck in `Pending`, including both Pods of Deployment `queue-worker` in Namespace `jobs`. Older Pods keep running.

Find the cause and fix it, so that new Pods are scheduled again and `queue-worker` runs with 2 ready Pods.

You need root on the instance: `sudo -i`.

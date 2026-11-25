---
title: Only new Services fail
host: dojo3
setup: last
docs: https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/ | Debug Services ; https://kubernetes.io/docs/reference/command-line-tools-reference/kube-proxy/ | kube-proxy
---
> Target: 6 minutes

In Namespace `stock` there are two Services:

- `catalog`, created a while ago, answers fine.
- `inventory`, created a few minutes ago, never answers, although its Pod runs and the Service has an endpoint.

The same happens to every Service created on this cluster since then. Find the cause in the cluster and fix it, so that `inventory` answers on port 80.

You can test with:

```
k -n stock run svc-test --rm -it --restart=Never --image=busybox:1 -- wget -qO- -T 3 inventory
```

---
title: A Pod that keeps coming back
host: dojo1
setup: last
docs: https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/ | Create static Pods ; https://kubernetes.io/docs/reference/config-api/kubelet-config.v1beta1/ | Kubelet Configuration
---
> Target: 5 minutes

Pod `node-debugger-dojo1-worker` in Namespace `default` gives everyone a root shell on its node. It was deleted twice, and each time it came back within seconds.

Remove it for good: it must not come back, not even after the kubelet or the node restarts.

Don't change the kubelet's configuration.

> ℹ️ You can reach the node with `ssh dojo1-node1` from `dojo1`

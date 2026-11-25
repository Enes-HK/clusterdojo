---
title: Node NotReady
host: dojo3
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/ | Troubleshooting Clusters ; https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/#kubelet-drop-in | kubelet drop-in file
setup: last
---
> Target: 6 minutes

Node `dojo3-worker` is `NotReady` and no new Pods get started on it.

Find the cause and fix it. The fix must also survive a reboot of the node.

> ℹ️ You can reach the node with `ssh dojo3-node1` from `dojo3`

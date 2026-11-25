---
title: Node NotReady, two faults
host: dojo3-node1
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/ | Troubleshooting Clusters ; https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/ | kubelet
setup: last
---
> Target: 7 minutes

Node `dojo3-worker` is `NotReady`.

1. Find out why and fix it, so the node is `Ready` and stays that way. The kubelet configuration file itself is fine, don't edit it
2. Write the **first** exit status you see for the kubelet service (the `status=` value in `systemctl status`, for example `1/FAILURE`) into `/home/student/answers/m2-01/status` on `dojo3`
3. From `dojo3`, create a Pod named `worker-probe` in Namespace `default` with image `nginx:1-alpine` that runs on `dojo3-worker`. Use `nodeName`

Start by reading the service status line by line. There's more than one fault.

You need root on the instance: `sudo -i`.

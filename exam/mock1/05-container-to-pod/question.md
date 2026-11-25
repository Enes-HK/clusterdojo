---
title: Which Pod owns this container?
host: dojo3
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/ | Debugging Kubernetes nodes with crictl
---
> Target: 5 minutes

A disk monitor on `dojo3` (the control plane node of this cluster) logged an alert to `/var/log/disk-alert.log`. It names a container only by the start of its container ID.

1. Find out which Pod and which container of that Pod the alert is about. Write them as `<namespace>/<pod>/<container>` into `/home/student/answers/m1-05/owner`
2. Write the image that container runs, exactly as the Pod spec names it, into `/home/student/answers/m1-05/image`

Don't change or delete anything.

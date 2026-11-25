---
title: A Pod that keeps restarting
host: dojo1
docs: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/ | Debug Running Pods ; https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/ | Assign Memory Resources ; https://kubernetes.io/docs/reference/kubectl/generated/kubectl_logs/ | kubectl logs
---
> Target: 6 minutes

The Pod of Deployment `invoice-worker` in Namespace `billing` keeps restarting.

1. Save the logs of the container instance that **crashed most recently** into `/home/student/answers/m1-04/previous.log`
2. Find out why the last container instance was terminated. Write its reason and exit code as `Reason/ExitCode` (for example `Error/1`) into `/home/student/answers/m1-04/termination`
3. Fix the Deployment so the Pod runs without restarts: give container `worker` a memory request of `64Mi` and a memory limit of `128Mi`. Don't change its command

---
title: Control plane keeps restarting
host: dojo4
docs: https://kubernetes.io/docs/tasks/debug/debug-cluster/ | Troubleshooting Clusters ; https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ | Liveness, Readiness and Startup Probes
setup: last
---
> Target: 8 minutes

Users of the cluster on `dojo4` report that `kubectl` works only for a few minutes at a time, then fails with "connection refused", then works again.

Find the cause and fix it so the kube-apiserver runs stable. Don't change anything that's unrelated to the problem.

Write the name of the field you had to fix (e.g. `spec.containers[].image`) into `/home/student/answers/m1-02/field`.

---
title: A stuck rollout
host: dojo1
docs: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/ | Deployments ; https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout/ | kubectl rollout
---
> Target: 6 minutes

Deployment `checkout` in Namespace `shop` was updated a few minutes ago. Since then only one of its three Pods is serving.

1. Find the change-cause of the update that broke it and write it into `/home/student/answers/m1-14/broken-change`.
2. The payment switch hasn't been approved yet, so bring `checkout` back to the revision with change-cause `enable cart v2`. Use the rollout history, don't rebuild the Pod template by hand.
3. Change the update strategy so that future updates never drop below 3 ready Pods and add at most one extra Pod at a time.
4. Keep at most 4 old ReplicaSets for this Deployment.

All three Pods must be ready at the end.

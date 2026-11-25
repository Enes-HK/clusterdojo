---
title: A Namespace stuck in Terminating
host: dojo3
docs: https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/ | Finalizers ; https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/ | Namespaces ; https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/ | Custom Resources
---
> Target: 6 minutes

Namespace `reports` was deleted a while ago, but it's still `Terminating`. The operator that managed its custom resources was uninstalled before that.

1. Find out what keeps the Namespace from being deleted, and let the deletion finish. Don't delete any CustomResourceDefinition, and don't edit the Namespace object itself
2. Write the name of the finalizer that blocked it into `/home/student/answers/m1-09/finalizer`

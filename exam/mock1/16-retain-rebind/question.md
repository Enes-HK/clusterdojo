---
title: Get a deleted claim's data back
host: dojo3
docs: https://kubernetes.io/docs/concepts/storage/persistent-volumes/ | Persistent Volumes ; https://kubernetes.io/docs/tasks/administer-cluster/change-pv-reclaim-policy/ | Change the Reclaim Policy of a PersistentVolume
---
> Target: 6 minutes

PersistentVolumeClaim `ledger-data` in Namespace `finance` was deleted by mistake. Its data is still on PersistentVolume `ledger-pv`, and Deployment `ledger` can't start without the claim.

Create PVC `ledger-data` again so that it binds to `ledger-pv` and the Pod of `ledger` starts with the old data.

- Don't delete or recreate `ledger-pv`, and keep its reclaim policy.
- Don't change the Deployment.

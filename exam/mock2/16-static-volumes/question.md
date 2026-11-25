---
title: Static volumes and StorageClass
host: dojo2
docs: https://kubernetes.io/docs/concepts/storage/persistent-volumes/ | Persistent Volumes ; https://kubernetes.io/docs/tasks/run-application/run-single-instance-stateful-application/ | Single-Instance Stateful Application
---
> Target: 9 minutes

Namespace `records` runs Deployment `scanner`, which writes to `/data/scan.log`. It's already configured to use the claim `records-claim`, but its Pod doesn't start. Directory `/mnt/records` exists **only** on node `dojo2-worker`.

1. Create a PersistentVolume named `records-pv` with capacity `3Gi`, access mode `ReadWriteOnce` and hostPath `/mnt/records`. It must only be usable on node `dojo2-worker`. Don't give it a StorageClass
2. Create a PersistentVolumeClaim named `records-claim` in Namespace `records` requesting `2Gi` with access mode `ReadWriteOnce`. It has to bind to `records-pv`
3. PersistentVolumeClaim `buffer-claim` in Namespace `records` was meant to use the existing PersistentVolume `premium-pv`, but it's still `Pending`. Make it bind to `premium-pv`. Keep its name, size and access mode

When you're done, `scanner` must be `Running` and `scan.log` must appear in `/mnt/records` on the node.

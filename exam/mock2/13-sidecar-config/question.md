---
title: Sidecar and config file
host: dojo1
docs: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/ | Sidecar Containers ; https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath | Volumes: using subPath
---
> Target: 7 minutes

Deployment `ingest` in Namespace `logging` runs container `app`, which writes its log to `/var/log/app/app.log`. Change the Deployment:

1. Add an `emptyDir` volume named `logs`, mounted at `/var/log/app` in container `app`
2. Add a **native** sidecar container named `shipper` with image `busybox:1` that starts **before** `app` and keeps running for the Pod's whole life. It runs `tail -F /var/log/app/app.log` and mounts the same volume
3. Mount key `app.conf` of the existing ConfigMap `ingest-config` into container `app` as the single file `/etc/app.conf`. The other files in `/etc` (e.g. `/etc/passwd`) must still be there

`kubectl logs` of container `shipper` should then show the app's log lines.

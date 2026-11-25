---
title: Init container, sidecar, Secret and probe
host: dojo2
docs: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/ | Init Containers ; https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/ | Distribute Credentials Securely ; https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ | Probes ; https://kubernetes.io/docs/concepts/storage/volumes/ | Volumes
---
> Target: 10 minutes

Namespace `payroll` contains Secret `pg-credentials` with keys `username` and `password`, and ConfigMap `payslip-config` with key `payroll.ini`.

Create a Deployment named `payslip` in Namespace `payroll` with `1` replica. All containers use image `busybox:1`, and all of them share one `emptyDir` volume mounted at `/shared`.

1. Init container `prepare` runs `echo ready > /shared/state.txt`
2. Container `app` runs `while true; do date >> /shared/app.log; sleep 3; done`
3. Container `app` gets environment variable `PG_USER` from key `username` and `PG_PASSWORD` from key `password` of Secret `pg-credentials`
4. In container `app`, key `payroll.ini` of the ConfigMap must appear as the **file** `/etc/payroll.ini`. The other files in `/etc` must stay visible
5. Container `app` has a readiness probe that runs this shell command every `10` seconds: `grep -q ready /shared/state.txt && test -s /shared/app.log`
6. Container `log-forwarder` runs next to `app` and runs `tail -F /shared/app.log`

The Pod must become `2/2 Running` and `Ready`.

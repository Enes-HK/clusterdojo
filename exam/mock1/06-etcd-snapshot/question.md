---
title: etcd snapshot
host: dojo2
docs: https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/ | Operating etcd clusters
---
> Target: 5 minutes

`etcdctl` and `etcdutl` are installed on `dojo2`.

1. Take a snapshot of the running etcd and save it as `/home/student/answers/m1-06/cluster-backup.db`. The endpoint and the certificate paths are in the etcd static Pod manifest
2. Check the snapshot with `etcdutl`, and save the `table` output of the status command to `/home/student/answers/m1-06/snapshot-info.txt`
3. Write the data directory etcd uses (the value of `--data-dir`) into `/home/student/answers/m1-06/datadir`

You need root on the instance: `sudo -i`.

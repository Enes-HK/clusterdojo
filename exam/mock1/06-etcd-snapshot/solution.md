**What this tests:** getting real paths from the manifest, instead of pasting the docs example with its placeholders.

**How to get there:** the manifest has every value you need:

```bash
ssh dojo2
sudo -i
grep -E 'cert-file|key-file|trusted-ca|listen-client|data-dir' /etc/kubernetes/manifests/etcd.yaml
```

Use the **server** (or healthcheck-client) certificate, not the `peer` one:

```bash
ETCDCTL_API=3 etcdctl snapshot save /home/student/answers/m1-06/cluster-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

etcdutl snapshot status /home/student/answers/m1-06/cluster-backup.db -w table | tee /home/student/answers/m1-06/snapshot-info.txt
echo /var/lib/etcd > /home/student/answers/m1-06/datadir
```

**Traps**
- Without the three TLS flags, `etcdctl` hangs on the connection and then times out. If it hangs, check the flags first.
- `<placeholders>` from the docs example must all be replaced.
- `snapshot status` is an offline command, so it uses `etcdutl` and needs no certificates.

**For a restore** (not part of this task): `etcdutl snapshot restore <file> --data-dir <new dir>`, then point the `etcd-data` hostPath in `etcd.yaml` at the new directory and wait for the static Pod to come back.

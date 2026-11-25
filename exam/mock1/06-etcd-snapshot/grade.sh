source /root/exam/bin/lib.sh
keys=$(on dojo2 "etcdutl snapshot status /home/student/answers/m1-06/cluster-backup.db -w json 2>/dev/null" | jq -r .totalKey 2>/dev/null)
[ "${keys:-0}" -gt 100 ] 2>/dev/null && pass "cluster-backup.db is a valid snapshot" || fail "cluster-backup.db is a valid snapshot" "keys: ${keys:-none}"
on dojo2 "grep -aq snapshot-canary /home/student/answers/m1-06/cluster-backup.db" && pass "Snapshot is of this cluster's etcd" || fail "Snapshot is of this cluster's etcd"
on dojo2 "grep -q 'HASH' /home/student/answers/m1-06/snapshot-info.txt && grep -q 'REVISION' /home/student/answers/m1-06/snapshot-info.txt" \
  && pass "snapshot-info.txt holds the table output" || fail "snapshot-info.txt holds the table output"
d=$(on dojo2 "cat /home/student/answers/m1-06/datadir 2>/dev/null" | tr -d '[:space:]')
[ "${d%/}" = /var/lib/etcd ] && pass "data-dir file is /var/lib/etcd" || fail "data-dir file is /var/lib/etcd" "found: $d"

source /root/exam/bin/lib.sh
on dojo2 "etcdctl snapshot save /home/student/answers/m1-06/cluster-backup.db --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  && etcdutl snapshot status /home/student/answers/m1-06/cluster-backup.db -w table > /home/student/answers/m1-06/snapshot-info.txt \
  && echo /var/lib/etcd > /home/student/answers/m1-06/datadir"

source /root/exam/bin/lib.sh
drop_ns dojo3 ops-tools
kc dojo3 create ns ops-tools
answers dojo3 m1-05
# three look-alike Pods on the control plane (tolerating everything, so a broken worker doesn't matter)
for p in metrics-relay audit-sync cache-prime; do
kc dojo3 apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata: {name: $p, namespace: ops-tools, labels: {app: $p}}
spec:
  nodeName: dojo3-control-plane
  tolerations: [{operator: Exists}]
  containers:
  - {name: main, image: "busybox:1", command: [sleep, "1d"]}
  - {name: uploader, image: "$( [ $p = audit-sync ] && echo 'busybox:1.36' || echo 'busybox:1' )", command: [sleep, "1d"]}
EOF
done
kc dojo3 -n ops-tools wait pod --all --for=condition=Ready --timeout=120s
id=$(on dojo3 "crictl ps --name '^uploader$' --label io.kubernetes.pod.name=audit-sync -q" | head -1)
[ -n "$id" ] || { echo "container not found"; exit 1; }
on dojo3 "printf '%s disk-monitor: container %s writes 2.1 GB/h into its writable layer (/var/lib/containerd) - please check\n' \"\$(date -Is)\" ${id:0:13} > /var/log/disk-alert.log; cat /var/log/disk-alert.log"

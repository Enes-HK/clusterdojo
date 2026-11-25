source /root/exam/bin/lib.sh
drop_ns dojo2 records
kc dojo2 delete pv records-pv premium-pv --ignore-not-found
kc dojo2 create ns records
on dojo2-node1 "rm -rf /mnt/records /mnt/premium; mkdir -p /mnt/records /mnt/premium && chmod 777 /mnt/records /mnt/premium"
on dojo2 "rm -rf /mnt/records"
# scanner already points at records-claim (which doesn't exist yet), but mounts it at /dat instead of /data:
# once the claim binds the Pod runs fine, and only the empty /mnt/records on the node shows the mistake
kc dojo2 apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata: {name: premium-pv}
spec:
  storageClassName: premium
  capacity: {storage: 2Gi}
  accessModes: [ReadWriteOnce]
  hostPath: {path: /mnt/premium}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: buffer-claim, namespace: records}
spec:
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 600Mi}}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: scanner, namespace: records}
spec:
  selector: {matchLabels: {app: scanner}}
  template:
    metadata: {labels: {app: scanner}}
    spec:
      containers:
      - name: scanner
        image: busybox:1
        command: [sh, -c, 'mkdir -p /data; while true; do date >> /data/scan.log; sleep 5; done']
        volumeMounts:
        - {name: data, mountPath: /dat}
      volumes:
      - name: data
        persistentVolumeClaim: {claimName: records-claim}
EOF

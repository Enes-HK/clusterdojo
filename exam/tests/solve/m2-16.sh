source /root/exam/bin/lib.sh
kc dojo2 -n records delete pvc buffer-claim --ignore-not-found
kc dojo2 apply -f - <<'Y'
apiVersion: v1
kind: PersistentVolume
metadata: {name: records-pv}
spec:
  capacity: {storage: 3Gi}
  accessModes: [ReadWriteOnce]
  hostPath: {path: /mnt/records}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - {key: kubernetes.io/hostname, operator: In, values: [dojo2-worker]}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: records-claim, namespace: records}
spec:
  storageClassName: ""
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 2Gi}}
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: buffer-claim, namespace: records}
spec:
  storageClassName: premium
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 600Mi}}
Y
kc dojo2 -n records patch deploy scanner --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/volumeMounts/0/mountPath","value":"/data"}]'
kc dojo2 -n records rollout status deploy/scanner --timeout=90s
sleep 7

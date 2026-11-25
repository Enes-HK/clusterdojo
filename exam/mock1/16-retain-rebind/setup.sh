source /root/exam/bin/lib.sh
drop_ns dojo3 finance
kc dojo3 delete pv ledger-pv scratch-pv --ignore-not-found --wait
on dojo3 "rm -rf /srv/ledger /srv/scratch && mkdir -p /srv/ledger /srv/scratch && printf 'account=operations\nbalance=4711.20\n' > /srv/ledger/ledger.db"
kc dojo3 create ns finance
# pv <name> <dir>: a 1Gi hostPath volume on the control plane, kept after its claim is gone
pv() {
kc dojo3 apply -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata: {name: $1}
spec:
  capacity: {storage: 1Gi}
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath: {path: $2, type: Directory}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions: [{key: kubernetes.io/hostname, operator: In, values: [dojo3-control-plane]}]
EOF
}
pv ledger-pv /srv/ledger
kc dojo3 apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: ledger-data, namespace: finance}
spec:
  storageClassName: manual
  volumeName: ledger-pv
  accessModes: [ReadWriteOnce]
  resources: {requests: {storage: 1Gi}}
EOF
wait_for 60 bash -c "[ \"\$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get pv ledger-pv -o jsonpath='{.status.phase}')\" = Bound ]"
kc dojo3 -n finance delete pvc ledger-data --wait
wait_for 60 bash -c "[ \"\$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get pv ledger-pv -o jsonpath='{.status.phase}')\" = Released ]"
kc dojo3 get pv ledger-pv -o jsonpath='{.metadata.uid}' > "$EXAM/state/m1-16-pv-uid"
# an empty volume of the same class and size: a new claim without volumeName may end up here
pv scratch-pv /srv/scratch
kc dojo3 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: ledger, namespace: finance}
spec:
  selector: {matchLabels: {app: ledger}}
  strategy: {type: Recreate}
  template:
    metadata: {labels: {app: ledger}}
    spec:
      tolerations: [{key: node-role.kubernetes.io/control-plane, effect: NoSchedule}]
      containers:
      - name: ledger
        image: busybox:1
        command: [sh, -c, 'cat /data/ledger.db || exit 1; echo "$(date) ledger opened" >> /data/access.log; sleep 1d']
        volumeMounts: [{name: data, mountPath: /data}]
      volumes: [{name: data, persistentVolumeClaim: {claimName: ledger-data}}]
EOF

source /root/exam/bin/lib.sh
kc dojo3 patch pv ledger-pv --type json -p '[{"op":"remove","path":"/spec/claimRef"}]'
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
kc dojo3 -n finance rollout status deploy/ledger --timeout=180s

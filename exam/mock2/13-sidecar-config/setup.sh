source /root/exam/bin/lib.sh
drop_ns dojo1 logging
kc dojo1 create ns logging
kc dojo1 apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata: {name: ingest-config, namespace: logging}
data:
  app.conf: |
    batch_size=500
    target=s3://acme-logs
  unused.conf: |
    debug=false
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: ingest, namespace: logging}
spec:
  replicas: 1
  selector: {matchLabels: {app: ingest}}
  template:
    metadata: {labels: {app: ingest}}
    spec:
      containers:
      - name: app
        image: busybox:1
        command: [sh, -c, 'mkdir -p /var/log/app; i=0; while true; do i=$((i+1)); echo "$(date) ingest batch $i ok" >> /var/log/app/app.log; sleep 5; done']
EOF

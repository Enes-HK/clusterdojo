source /root/exam/bin/lib.sh
kc dojo1 label node dojo1-worker topology.kubernetes.io/zone=zone-a --overwrite
kc dojo1 label node dojo1-worker2 topology.kubernetes.io/zone=zone-b --overwrite
drop_ns dojo1 cdn
kc dojo1 create ns cdn
kc dojo1 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: edge-cache, namespace: cdn}
spec:
  replicas: 4
  selector: {matchLabels: {app: edge-cache}}
  template:
    metadata: {labels: {app: edge-cache}}
    spec:
      nodeSelector: {kubernetes.io/hostname: dojo1-worker}
      containers:
      - name: cache
        image: nginx:1-alpine
        resources: {requests: {cpu: 10m, memory: 16Mi}}
EOF
kc dojo1 -n cdn rollout status deploy/edge-cache --timeout=120s

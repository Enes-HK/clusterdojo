source /root/exam/bin/lib.sh
kc dojo1 uncordon dojo1-worker2
drop_ns dojo1 warehouse
kc dojo1 create ns warehouse
# dojo1-worker is cordoned only while the Pods are placed, so they all start on dojo1-worker2
trap 'kc dojo1 uncordon dojo1-worker >/dev/null; give_back' EXIT
kc dojo1 cordon dojo1-worker
kc dojo1 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: stock-api, namespace: warehouse}
spec:
  replicas: 3
  selector: {matchLabels: {app: stock-api}}
  template:
    metadata: {labels: {app: stock-api}}
    spec:
      containers:
      - name: api
        image: nginx:1-alpine
        volumeMounts: [{name: cache, mountPath: /var/cache/nginx}]
      volumes: [{name: cache, emptyDir: {}}]
---
# minAvailable 3 with 3 replicas: no Pod may ever be evicted, so a drain waits forever
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata: {name: stock-api, namespace: warehouse}
spec:
  minAvailable: 3
  selector: {matchLabels: {app: stock-api}}
---
apiVersion: v1
kind: Pod
metadata: {name: legacy-report, namespace: warehouse, labels: {app: legacy-report}}
spec:
  nodeName: dojo1-worker2
  containers:
  - name: report
    image: busybox:1
    command: [sh, -c, 'while true; do echo "$(date) report generated"; sleep 60; done']
EOF
kc dojo1 -n warehouse rollout status deploy/stock-api --timeout=120s
kc dojo1 -n warehouse wait pod legacy-report --for=condition=Ready --timeout=90s
kc dojo1 uncordon dojo1-worker

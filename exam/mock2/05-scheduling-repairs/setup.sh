source /root/exam/bin/lib.sh
drop_ns dojo2 platform
kc dojo2 create ns platform
kc dojo2 label node dojo2-worker drive=nvme --overwrite
kc dojo2 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: agent, namespace: platform}
spec:
  replicas: 1
  selector: {matchLabels: {app: agent}}
  template:
    metadata: {labels: {app: agent}}
    spec:
      containers: [{name: agent, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: v1
kind: Pod
metadata: {name: batch-runner, namespace: platform, labels: {app: batch-runner}}
spec:
  schedulerName: low-latency-scheduler
  containers: [{name: runner, image: "busybox:1", command: [sh, -c, 'echo batch started; sleep 1d']}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: waiting, namespace: platform}
spec:
  selector: {matchLabels: {app: waiting}}
  template:
    metadata: {labels: {app: waiting}}
    spec:
      nodeSelector: {drive: sata}
      containers: [{name: waiting, image: "nginx:1-alpine"}]
EOF
kc dojo2 -n platform rollout status deploy/agent --timeout=90s

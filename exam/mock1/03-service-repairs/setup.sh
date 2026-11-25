source /root/exam/bin/lib.sh
drop_ns dojo2 support external
kc dojo2 create ns support
kc dojo2 create ns external
kc dojo2 apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata: {name: remote-db, namespace: external, labels: {app: remote-db}}
spec:
  containers:
  - {name: db, image: "hashicorp/http-echo:1.0", args: ["-listen=:9500", "-text=warehouse-db-ok"]}
---
apiVersion: v1
kind: Pod
metadata: {name: toolbox, namespace: support, labels: {app: toolbox}}
spec:
  containers: [{name: toolbox, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: reporter, namespace: support}
spec:
  selector: {matchLabels: {app: reporter}}
  template:
    metadata: {labels: {app: reporter}}
    spec:
      containers:
      - name: reporter
        image: "hashicorp/http-echo:1.0"
        args: ["-listen=:8080", "-text=reporter-ok"]
        ports: [{containerPort: 8080}]
        readinessProbe:
          httpGet: {path: /, port: 8081}
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata: {name: reporter, namespace: support}
spec:
  selector: {app: reporter}
  ports: [{port: 80, targetPort: 8080}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: helpdesk, namespace: support}
spec:
  replicas: 2
  selector: {matchLabels: {app: helpdesk}}
  template:
    metadata: {labels: {app: helpdesk, version: v1}}
    spec:
      containers:
      - {name: helpdesk, image: "hashicorp/http-echo:1.0", args: ["-listen=:8080", "-text=helpdesk-ok"]}
---
apiVersion: v1
kind: Service
metadata: {name: helpdesk, namespace: support}
spec:
  selector: {app: helpdesk, tier: backend}
  ports: [{port: 80, targetPort: 8080}]
EOF
kc dojo2 -n support wait pod toolbox remote-db --for=condition=Ready --timeout=90s 2>/dev/null
kc dojo2 -n support rollout status deploy/helpdesk --timeout=90s
kc dojo2 -n external wait pod --all --for=condition=Ready --timeout=90s

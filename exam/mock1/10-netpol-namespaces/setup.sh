source /root/exam/bin/lib.sh
for n in treasury dashboard dashboard-staging sre; do drop_ns dojo1 $n; kc dojo1 create ns $n; done
kc dojo1 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: engine, namespace: treasury}
spec:
  selector: {matchLabels: {app: engine}}
  template:
    metadata: {labels: {app: engine}}
    spec:
      containers:
      - {name: app, image: "hashicorp/http-echo:1.0", args: ["-listen=:9000", "-text=engine-app"]}
      - {name: admin, image: "hashicorp/http-echo:1.0", args: ["-listen=:9001", "-text=engine-admin"]}
      - {name: tools, image: "busybox:1", command: [sleep, "1d"]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: kvstore, namespace: treasury}
spec:
  selector: {matchLabels: {app: kvstore}}
  template:
    metadata: {labels: {app: kvstore}}
    spec:
      containers:
      - {name: main, image: "hashicorp/http-echo:1.0", args: ["-listen=:11211", "-text=kvstore-11211"]}
      - {name: replica, image: "hashicorp/http-echo:1.0", args: ["-listen=:11212", "-text=kvstore-11212"]}
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: reconciler, namespace: treasury}
spec:
  selector: {matchLabels: {app: reconciler}}
  template:
    metadata: {labels: {app: reconciler}}
    spec:
      containers: [{name: reconciler, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: console, namespace: dashboard}
spec:
  selector: {matchLabels: {app: console}}
  template:
    metadata: {labels: {app: console}}
    spec:
      containers: [{name: console, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: visitor, namespace: dashboard}
spec:
  selector: {matchLabels: {app: visitor}}
  template:
    metadata: {labels: {app: visitor}}
    spec:
      containers: [{name: visitor, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: console, namespace: dashboard-staging}
spec:
  selector: {matchLabels: {app: console}}
  template:
    metadata: {labels: {app: console}}
    spec:
      containers: [{name: console, image: "busybox:1", command: [sleep, "1d"]}]
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: alerts, namespace: sre}
spec:
  selector: {matchLabels: {app: alerts}}
  template:
    metadata: {labels: {app: alerts}}
    spec:
      containers: [{name: alerts, image: "busybox:1", command: [sleep, "1d"]}]
EOF
for d in treasury/engine treasury/kvstore treasury/reconciler dashboard/console dashboard/visitor dashboard-staging/console sre/alerts; do
  kc dojo1 -n ${d%/*} rollout status deploy/${d#*/} --timeout=120s
done

source /root/exam/bin/lib.sh
drop_ns dojo1 billing
kc dojo1 create ns billing
answers dojo1 m1-04
# the worker loads ~40 MB into a shell variable: far above its 24Mi limit, so it is OOMKilled on every start
kc dojo1 apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata: {name: invoice-worker, namespace: billing}
spec:
  replicas: 1
  selector: {matchLabels: {app: invoice-worker}}
  template:
    metadata: {labels: {app: invoice-worker}}
    spec:
      containers:
      - name: worker
        image: busybox:1
        command: [sh, -c, 'echo "invoice-worker 3.1 starting"; echo "loading open invoices into memory"; x=$(head -c 40000000 /dev/zero | tr "\000" a); echo "loaded ${#x} bytes, waiting for jobs"; sleep 1d']
        resources:
          requests: {memory: 16Mi}
          limits: {memory: 24Mi}
EOF
# wait until it has crashed at least once, so there is a previous instance to read
wait_for 120 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n billing get pod -l app=invoice-worker -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' | grep -qv '^0$'"
kc dojo1 -n billing get pods

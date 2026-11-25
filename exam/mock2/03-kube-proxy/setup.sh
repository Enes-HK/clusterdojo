source /root/exam/bin/lib.sh
# a working kube-proxy first (a previous run of this setup leaves it broken)
kc dojo3 -n kube-system patch ds kube-proxy --type=json -p '[{"op":"replace","path":"/spec/template/spec/nodeSelector","value":{"kubernetes.io/os":"linux"}}]'
wait_for 90 bash -c "ssh dojo3 \"crictl ps --name '^kube-proxy\$' -q\" | grep -q ."
drop_ns dojo3 stock
kc dojo3 create ns stock
# app <name>: an echo server on the control plane (the worker of this cluster may be down because of another task)
app() {
kc dojo3 apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata: {name: $1, namespace: stock}
spec:
  selector: {matchLabels: {app: $1}}
  template:
    metadata: {labels: {app: $1}}
    spec:
      nodeSelector: {kubernetes.io/hostname: dojo3-control-plane}
      tolerations: [{key: node-role.kubernetes.io/control-plane, effect: NoSchedule}]
      containers:
      - name: echo
        image: hashicorp/http-echo:1.0
        args: [-listen=:8080, -text=$1-ok]
EOF
}
app catalog
app inventory
kc dojo3 -n stock rollout status deploy/catalog --timeout=120s
kc dojo3 -n stock rollout status deploy/inventory --timeout=120s
kc dojo3 -n stock expose deploy catalog --port 80 --target-port 8080
sleep 5
# kube-proxy now matches no node: its Pods go away, the rules they wrote stay, new Services get none
kc dojo3 -n kube-system patch ds kube-proxy --type=merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux","node-role.kubernetes.io/proxy":""}}}}}'
wait_for 90 bash -c "! ssh dojo3 \"crictl ps --name '^kube-proxy\$' -q\" | grep -q ."
kc dojo3 -n stock expose deploy inventory --port 80 --target-port 8080

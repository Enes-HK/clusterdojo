source /root/exam/bin/lib.sh
answers dojo2 m2-04
ms() { kc dojo2 -n kube-system "$@"; }
# a working metrics-server first: while it's broken, deleting a Namespace hangs
if ! ms get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q kubelet-insecure-tls; then
  ms patch deploy metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi
ms rollout status deploy/metrics-server --timeout=180s
drop_ns dojo2 analytics
kc dojo2 create ns analytics
# pod <name> <MB held in memory>
pod() {
kc dojo2 apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata: {name: $1, namespace: analytics, labels: {app: etl}}
spec:
  containers:
  - name: etl
    image: busybox:1
    command: [sh, -c, 'x=\$(head -c ${2}000000 /dev/zero | tr "\000" a); echo "$1 holds \${#x} bytes"; sleep 1d']
    resources: {limits: {memory: 256Mi}}
EOF
}
pod etl-loader 8
pod etl-indexer 70
pod etl-reporter 20
kc dojo2 -n analytics wait pod --all --for=condition=Ready --timeout=120s
# the break: without --kubelet-insecure-tls metrics-server can't scrape kind's kubelets.
# Recreate instead of a rolling update, so the old, working Pod doesn't keep serving.
args=$(ms get deploy metrics-server -o json | jq -c '[.spec.template.spec.containers[0].args[] | select(. != "--kubelet-insecure-tls")]')
ms patch deploy metrics-server --type=json -p "[{\"op\":\"replace\",\"path\":\"/spec/strategy\",\"value\":{\"type\":\"Recreate\"}},{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/args\",\"value\":$args}]"
wait_for 120 bash -c "! kubectl --kubeconfig $EXAM/kubeconfigs/dojo2 top nodes"

source /root/exam/bin/lib.sh
# a static Pod from a non-default staticPodPath on dojo1-worker
on dojo1-node1 'mkdir -p /etc/kubelet.d && cat > /etc/kubelet.d/node-tools.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: node-debugger
  namespace: default
  labels: {app: node-debugger}
spec:
  hostPID: true
  containers:
  - name: shell
    image: busybox:1
    command: [sleep, 1d]
    securityContext: {privileged: true}
EOF
sed -i "s#^staticPodPath: .*#staticPodPath: /etc/kubelet.d#" /var/lib/kubelet/config.yaml
systemctl restart kubelet'
wait_for 120 kc dojo1 -n default get pod node-debugger-dojo1-worker
kc dojo1 -n default wait pod node-debugger-dojo1-worker --for=condition=Ready --timeout=90s

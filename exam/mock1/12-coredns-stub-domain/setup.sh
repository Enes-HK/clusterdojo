source /root/exam/bin/lib.sh
# CoreDNS of this cluster back to its original config (an earlier attempt may have changed it)
if [ -s "$EXAM/state/coredns-dojo2.yaml" ] && [ "$(kc dojo2 -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')" != "$(cat "$EXAM/state/coredns-dojo2.yaml")" ]; then
  kc dojo2 -n kube-system create cm coredns --from-file=Corefile="$EXAM/state/coredns-dojo2.yaml" --dry-run=client -o yaml | kc dojo2 apply -f -
  kc dojo2 -n kube-system rollout restart deploy/coredns
fi
drop_ns dojo2 corp-dns
kc dojo2 create ns corp-dns
img=$(kc dojo2 -n kube-system get deploy coredns -o jsonpath='{.spec.template.spec.containers[0].image}')
# the "company" DNS server: a second CoreDNS that only knows corp.internal
kc dojo2 apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata: {name: corp-zone, namespace: corp-dns}
data:
  Corefile: |
    corp.internal:53 {
      hosts {
        10.10.10.10 wiki.corp.internal
        10.10.10.20 git.corp.internal
        10.10.10.30 build.ci.corp.internal
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: corp-resolver, namespace: corp-dns}
spec:
  selector: {matchLabels: {app: corp-resolver}}
  template:
    metadata: {labels: {app: corp-resolver}}
    spec:
      containers:
      - name: dns
        image: $img
        args: [-conf, /etc/coredns/Corefile]
        securityContext: {capabilities: {add: [NET_BIND_SERVICE]}}
        volumeMounts: [{name: zone, mountPath: /etc/coredns}]
      volumes: [{name: zone, configMap: {name: corp-zone}}]
---
apiVersion: v1
kind: Service
metadata: {name: corp-resolver, namespace: corp-dns}
spec:
  selector: {app: corp-resolver}
  ports:
  - {name: dns, port: 53, protocol: UDP}
  - {name: dns-tcp, port: 53, protocol: TCP}
EOF
kc dojo2 -n corp-dns rollout status deploy/corp-resolver --timeout=120s
kc dojo2 -n kube-system rollout status deploy/coredns --timeout=120s

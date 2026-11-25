source /root/exam/bin/lib.sh
kc dojo2 -n kube-system rollout status deploy/coredns --timeout=30s >/dev/null 2>&1
out=$(probe dojo2 default busybox:1 app=dns-check -- sh -c 'for n in wiki.corp.internal git.corp.internal build.ci.corp.internal kubernetes.default.svc.cluster.local; do echo "== $n"; nslookup -timeout=3 $n 2>&1; done')
ans() { echo "$out" | awk -v n="== $1" '$0==n{f=1;next} /^== /{f=0} f' | grep -A1 "^Name:" | grep -o 'Address:[[:space:]]*[0-9.]*' | awk '{print $2}' | head -1; }
[ "$(ans wiki.corp.internal)" = 10.10.10.10 ] && [ "$(ans git.corp.internal)" = 10.10.10.20 ] \
  && pass "wiki and git.corp.internal resolve through corp-resolver" || fail "wiki and git.corp.internal resolve through corp-resolver" "wiki=$(ans wiki.corp.internal) git=$(ans git.corp.internal)"
[ "$(ans build.ci.corp.internal)" = 10.10.10.30 ] && pass "Deeper names (build.ci.corp.internal) resolve too" || fail "Deeper names (build.ci.corp.internal) resolve too"
[ "$(ans kubernetes.default.svc.cluster.local)" = "$(kc dojo2 get svc kubernetes -o jsonpath='{.spec.clusterIP}')" ] \
  && pass "Cluster names still resolve" || fail "Cluster names still resolve"
cf=$(kc dojo2 -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')
ip=$(kc dojo2 -n corp-dns get svc corp-resolver -o jsonpath='{.spec.clusterIP}')
echo "$cf" | grep -q "forward[[:space:]]\+\.[[:space:]]\+$ip" && pass "Corefile forwards corp.internal to the ClusterIP $ip" || fail "Corefile forwards corp.internal to the ClusterIP $ip"
[ "$(kc dojo2 -n kube-system get deploy coredns -o jsonpath='{.status.readyReplicas}')" = 2 ] && pass "CoreDNS Pods ready" || fail "CoreDNS Pods ready"

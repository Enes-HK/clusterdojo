source /root/exam/bin/lib.sh
st=$(kc dojo3 get node dojo3-worker -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$st" = True ] && pass "Node dojo3-worker is Ready" || fail "Node dojo3-worker is Ready" "Ready=$st"
[ "$(on dojo3-node1 systemctl is-active kubelet)" = active ] && pass "kubelet service is running" || fail "kubelet service is running"
[ "$(on dojo3-node1 systemctl is-enabled kubelet)" = enabled ] && pass "kubelet service enabled (starts after reboot)" \
  || fail "kubelet service enabled (starts after reboot)"
on dojo3 "cat /home/student/answers/m2-01/status 2>/dev/null" | grep -q '203' && pass "First exit status written (203/EXEC)" \
  || fail "First exit status written (203/EXEC)" "found: $(on dojo3 'cat /home/student/answers/m2-01/status 2>/dev/null')"
p=$(kc dojo3 get pod worker-probe -o jsonpath='{.status.phase}/{.spec.nodeName}/{.spec.containers[0].image}' 2>/dev/null)
[ "$p" = "Running/dojo3-worker/nginx:1-alpine" ] && pass "Pod worker-probe running on dojo3-worker" \
  || fail "Pod worker-probe running on dojo3-worker" "phase/node/image: $p"

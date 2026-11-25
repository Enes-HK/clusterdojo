source /root/exam/bin/lib.sh
st=$(kc dojo3 get node dojo3-worker -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
[ "$st" = True ] && pass "Node dojo3-worker is Ready" || fail "Node dojo3-worker is Ready" "Ready=$st"
[ "$(on dojo3-node1 systemctl is-active kubelet)" = active ] && pass "kubelet service is running" || fail "kubelet service is running"
[ "$(on dojo3-node1 systemctl is-enabled kubelet)" = enabled ] && pass "kubelet service enabled (starts after reboot)" \
  || fail "kubelet service enabled (starts after reboot)"

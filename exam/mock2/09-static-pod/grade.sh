source /root/exam/bin/lib.sh
[ -z "$(on dojo1-node1 'grep -rls "name: node-debugger" /etc/kubelet.d /etc/kubernetes/manifests 2>/dev/null')" ] \
  && pass "Manifest removed from the static Pod folder" || fail "Manifest removed from the static Pod folder"
[ "$(on dojo1-node1 "grep '^staticPodPath:' /var/lib/kubelet/config.yaml" | awk '{print $2}')" = /etc/kubelet.d ] \
  && pass "kubelet configuration unchanged" || fail "kubelet configuration unchanged"
wait_for 30 bash -c "! kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n default get pod node-debugger-dojo1-worker" \
  && pass "Pod node-debugger-dojo1-worker gone" || fail "Pod node-debugger-dojo1-worker gone"
[ -z "$(on dojo1-node1 'crictl pods --name node-debugger --state ready -q')" ] && pass "No node-debugger container on the node" || fail "No node-debugger container on the node"
[ "$(on dojo1-node1 systemctl is-active kubelet)" = active ] \
  && [ "$(kc dojo1 get node dojo1-worker -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')" = True ] \
  && pass "kubelet running, node Ready" || fail "kubelet running, node Ready"

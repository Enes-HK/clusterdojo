source /root/exam/bin/lib.sh
on dojo4 "grep -q -- '- --kubeconfig=/etc/kubernetes/scheduler.conf' /etc/kubernetes/manifests/kube-scheduler.yaml" \
  && pass "kube-scheduler uses /etc/kubernetes/scheduler.conf" || fail "kube-scheduler uses /etc/kubernetes/scheduler.conf"
[ "$(kc dojo4 -n kube-system get pod kube-scheduler-dojo4-control-plane -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ] \
  && pass "kube-scheduler Pod ready" || fail "kube-scheduler Pod ready"
n=sched-check-$RANDOM
kc dojo4 -n default run $n --image=busybox:1 --restart=Never --command -- sleep 30 >/dev/null 2>&1
wait_for 30 bash -c "[ -n \"\$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo4 -n default get pod $n -o jsonpath='{.spec.nodeName}')\" ]" \
  && pass "A new Pod gets scheduled" || fail "A new Pod gets scheduled"
kc dojo4 -n default delete pod $n --now >/dev/null 2>&1
kc dojo4 -n jobs rollout status deploy/queue-worker --timeout=30s >/dev/null 2>&1
[ "$(kc dojo4 -n jobs get deploy queue-worker -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 2 ] \
  && pass "queue-worker: 2 Pods ready" || fail "queue-worker: 2 Pods ready"

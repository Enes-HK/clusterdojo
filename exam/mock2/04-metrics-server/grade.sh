source /root/exam/bin/lib.sh
kc dojo2 -n kube-system rollout status deploy/metrics-server --timeout=30s >/dev/null 2>&1
[ "$(kc dojo2 get apiservice v1beta1.metrics.k8s.io -o jsonpath='{.status.conditions[?(@.type=="Available")].status}' 2>/dev/null)" = True ] \
  && pass "Metrics API available" || fail "Metrics API available" "$(kc dojo2 get apiservice v1beta1.metrics.k8s.io -o jsonpath='{.status.conditions[0].message}' 2>/dev/null)"
wait_for 20 kc dojo2 top nodes && pass "kubectl top nodes works" || fail "kubectl top nodes works"
wait_for 20 kc dojo2 -n analytics top pods && pass "kubectl top pods works" || fail "kubectl top pods works"
a=$(on dojo2 "cat $ANS/m2-04/top-pod 2>/dev/null" | tr -d '\r' | sed 's/^ *//;s/ *$//;s#^pod/##;s#^analytics/##' | sed '/^$/d')
[ "$a" = etl-indexer ] && pass "top-pod names the Pod with the most memory" || fail "top-pod names the Pod with the most memory" "found: '$a'"

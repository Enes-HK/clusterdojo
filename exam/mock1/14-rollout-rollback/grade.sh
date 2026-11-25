source /root/exam/bin/lib.sh
a=$(on dojo1 "cat $ANS/m1-14/broken-change 2>/dev/null" | tr -d '\r' | sed 's/^ *//;s/ *$//' | sed '/^$/d')
[ "$a" = "nginx patch update" ] && pass "broken-change names the broken update" || fail "broken-change names the broken update" "found: '$a'"
kc dojo1 -n shop rollout status deploy/checkout --timeout=30s >/dev/null 2>&1
d=$(kc dojo1 -n shop get deploy checkout -o json 2>/dev/null)
c=$(echo "$d" | jq -c '.spec.template.spec.containers[0]')
echo "$c" | jq -e '.image=="nginx:1-alpine" and ([.env[]? | "\(.name)=\(.value)"] | sort == ["FEATURE_CART=v2"])' >/dev/null \
  && pass "Pod template is the 'enable cart v2' revision" || fail "Pod template is the 'enable cart v2' revision""$(echo "$c" | jq -c '{image,env}')"
echo "$d" | jq -e '(.spec.paused // false)==false' >/dev/null && pass "Rollout not paused" || fail "Rollout not paused"
echo "$d" | jq -e '.status.readyReplicas==3 and .status.updatedReplicas==3 and (.status.unavailableReplicas // 0)==0 and .status.replicas==3' >/dev/null \
  && pass "3 of 3 Pods ready, all on the current revision" || fail "3 of 3 Pods ready, all on the current revision"
echo "$d" | jq -e '.spec.strategy.type=="RollingUpdate" and (.spec.strategy.rollingUpdate.maxUnavailable|tostring)=="0" and (.spec.strategy.rollingUpdate.maxSurge|tostring)=="1"' >/dev/null \
  && pass "Strategy: maxUnavailable 0, maxSurge 1" || fail "Strategy: maxUnavailable 0, maxSurge 1" "$(echo "$d" | jq -c .spec.strategy)"
[ "$(echo "$d" | jq .spec.revisionHistoryLimit)" = 4 ] && pass "revisionHistoryLimit 4" || fail "revisionHistoryLimit 4"
kc dojo1 -n shop get rs -l app=checkout -o json | jq -e '[.items[] | select(.metadata.annotations["kubernetes.io/change-cause"]=="nginx patch update")] | length==1' >/dev/null \
  && pass "History kept (rolled back, not recreated)" || fail "History kept (rolled back, not recreated)"

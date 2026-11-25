source /root/exam/bin/lib.sh
[ "$(kc dojo1 get node dojo1-worker2 -o jsonpath='{.spec.unschedulable}')" = true ] && pass "dojo1-worker2 unschedulable" || fail "dojo1-worker2 unschedulable"
left=$(kc dojo1 get pod -A --field-selector spec.nodeName=dojo1-worker2 -o json | jq -r '.items[]
  | select(.metadata.deletionTimestamp == null)
  | select(([.metadata.ownerReferences[]?.kind] | index("DaemonSet")) | not)
  | .metadata.namespace + "/" + .metadata.name')
[ -z "$left" ] && pass "Only DaemonSet Pods left on dojo1-worker2" || fail "Only DaemonSet Pods left on dojo1-worker2" "$(echo $left)"
pdb=$(kc dojo1 -n warehouse get pdb stock-api -o json 2>/dev/null)
echo "$pdb" | jq -e '((.spec.minAvailable|tostring)=="2" and .spec.maxUnavailable==null) or ((.spec.maxUnavailable|tostring)=="1" and .spec.minAvailable==null)' >/dev/null \
  && echo "$pdb" | jq -e '.spec.selector.matchLabels == {"app":"stock-api"}' >/dev/null \
  && pass "PDB stock-api keeps exactly 2 of 3 Pods available" || fail "PDB stock-api keeps exactly 2 of 3 Pods available" "$(echo "$pdb" | jq -c '{minAvailable:.spec.minAvailable,maxUnavailable:.spec.maxUnavailable}')"
kc dojo1 -n warehouse rollout status deploy/stock-api --timeout=30s >/dev/null 2>&1
[ "$(kc dojo1 -n warehouse get deploy stock-api -o jsonpath='{.status.readyReplicas}')" = 3 ] && pass "stock-api: 3 Pods ready" || fail "stock-api: 3 Pods ready"
p=$(kc dojo1 -n warehouse get pod legacy-report -o json 2>/dev/null)
echo "$p" | jq -e '.status.phase=="Running" and .spec.nodeName != "dojo1-worker2" and .spec.containers[0].image=="busybox:1"
  and (.spec.containers[0].command | join(" ") | test("report generated")) and .metadata.labels.app=="legacy-report"' >/dev/null \
  && pass "legacy-report running unchanged on another node" || fail "legacy-report running unchanged on another node" "$(echo "$p" | jq -r '(.status.phase // "missing") + " on " + (.spec.nodeName // "-")')"

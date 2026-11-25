source /root/exam/bin/lib.sh
kc dojo1 -n cdn rollout status deploy/edge-cache --timeout=30s >/dev/null 2>&1
d=$(kc dojo1 -n cdn get deploy edge-cache -o json 2>/dev/null)
s=$(echo "$d" | jq -c .spec.template.spec)
echo "$s" | jq -e '(.nodeSelector["kubernetes.io/hostname"] // null)==null and (.nodeName // null)==null and ([.affinity.nodeAffinity? // empty] | length)==0' >/dev/null \
  && pass "No longer tied to one node" || fail "No longer tied to one node"
tsc=$(echo "$s" | jq -c '[.topologySpreadConstraints[]? | select(.topologyKey=="topology.kubernetes.io/zone")]')
echo "$tsc" | jq -e 'length==1 and .[0].maxSkew==1 and .[0].whenUnsatisfiable=="DoNotSchedule"' >/dev/null \
  && pass "Spread constraint on the zone label: maxSkew 1, DoNotSchedule" || fail "Spread constraint on the zone label: maxSkew 1, DoNotSchedule" "$tsc"
lbl=$(echo "$d" | jq -c .spec.template.metadata.labels)
echo "$tsc" | jq -e --argjson l "$lbl" '.[0].labelSelector.matchLabels as $m | ($m|length)>0 and ([$m|to_entries[] | $l[.key]==.value] | all)' >/dev/null \
  && pass "Constraint selects the Pods of edge-cache" || fail "Constraint selects the Pods of edge-cache" "labelSelector: $(echo "$tsc" | jq -c '.[0].labelSelector')"
echo "$d" | jq -e '.spec.replicas==6 and .status.readyReplicas==6 and .status.updatedReplicas==6 and .status.replicas==6' >/dev/null \
  && pass "6 replicas ready" || fail "6 replicas ready" "$(echo "$d" | jq -c '{spec:.spec.replicas,ready:.status.readyReplicas}')"
z=$(for n in $(live dojo1 cdn app=edge-cache .spec.nodeName); do kc dojo1 get node "$n" -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'; echo; done | sort | uniq -c | awk '{printf "%s=%s ", $2, $1}')
[ "$z" = "zone-a=3 zone-b=3 " ] && pass "3 Pods in each zone" || fail "3 Pods in each zone" "found: $z"

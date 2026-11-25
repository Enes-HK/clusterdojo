source /root/exam/bin/lib.sh
pv=$(kc dojo3 get pv ledger-pv -o json 2>/dev/null)
[ -n "$pv" ] && [ "$(echo "$pv" | jq -r .metadata.uid)" = "$(cat "$EXAM/state/m1-16-pv-uid" 2>/dev/null)" ] \
  && pass "ledger-pv is the original volume" || fail "ledger-pv is the original volume" "deleted or recreated"
[ "$(echo "$pv" | jq -r .spec.persistentVolumeReclaimPolicy)" = Retain ] && pass "Reclaim policy still Retain" || fail "Reclaim policy still Retain"
pvc=$(kc dojo3 -n finance get pvc ledger-data -o json 2>/dev/null)
[ "$(echo "$pvc" | jq -r '.status.phase + "/" + .spec.volumeName')" = "Bound/ledger-pv" ] \
  && [ "$(echo "$pv" | jq -r .spec.claimRef.uid)" = "$(echo "$pvc" | jq -r .metadata.uid)" ] \
  && pass "PVC ledger-data bound to ledger-pv" || fail "PVC ledger-data bound to ledger-pv" "$(echo "$pvc" | jq -r '(.status.phase // "missing") + " " + (.spec.volumeName // "")')"
c=$(kc dojo3 -n finance get deploy ledger -o json | jq -cS '.spec.template.spec | {v:.volumes, m:.containers[0].volumeMounts}')
[ "$c" = '{"m":[{"mountPath":"/data","name":"data"}],"v":[{"name":"data","persistentVolumeClaim":{"claimName":"ledger-data"}}]}' ] \
  && pass "Deployment ledger unchanged" || fail "Deployment ledger unchanged"
kc dojo3 -n finance rollout status deploy/ledger --timeout=30s >/dev/null 2>&1
pod=$(live dojo3 finance app=ledger | head -1)
kc dojo3 -n finance logs "$pod" 2>/dev/null | grep -q 'balance=4711.20' && pass "ledger runs with the old data" || fail "ledger runs with the old data"

source /root/exam/bin/lib.sh
kc dojo2 -n platform rollout status deploy/agent --timeout=30s >/dev/null 2>&1
a=$(kc dojo2 -n platform get deploy agent -o json 2>/dev/null)
echo "$a" | jq -e '[.spec.template.spec.tolerations[]? | select(.key=="maintenance" and .effect=="NoExecute" and .tolerationSeconds==300
  and ((.operator=="Equal" and .value=="planned") or (.operator=="Exists")))] | length == 1' >/dev/null \
  && pass "agent tolerates maintenance=planned:NoExecute for 300 seconds" || fail "agent tolerates maintenance=planned:NoExecute for 300 seconds"
[ "$(echo "$a" | jq -r '.status.readyReplicas')" = 1 ] && pass "agent is running" || fail "agent is running"
[ -z "$(kc dojo2 get nodes -o jsonpath='{.items[*].spec.taints[?(@.key=="maintenance")].key}' 2>/dev/null)" ] \
  && pass "No node was tainted" || fail "No node was tainted"

p=$(kc dojo2 -n platform get pod batch-runner -o json 2>/dev/null)
[ "$(echo "$p" | jq -r '.status.phase')" = Running ] && pass "batch-runner is Running" || fail "batch-runner is Running" "phase: $(echo "$p" | jq -r '.status.phase')"
[ "$(echo "$p" | jq -r '.spec.schedulerName')" = default-scheduler ] && pass "batch-runner uses the default scheduler" \
  || fail "batch-runner uses the default scheduler" "schedulerName: $(echo "$p" | jq -r '.spec.schedulerName')"
[ "$(echo "$p" | jq -c '[.spec.containers[0].image, .spec.containers[0].command]')" = '["busybox:1",["sh","-c","echo batch started; sleep 1d"]]' ] \
  && pass "batch-runner keeps its image and command" || fail "batch-runner keeps its image and command"

kc dojo2 -n platform rollout status deploy/waiting --timeout=30s >/dev/null 2>&1
[ "$(kc dojo2 -n platform get deploy waiting -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 1 ] \
  && [ "$(kc dojo2 -n platform get deploy waiting -o jsonpath='{.spec.template.spec.nodeSelector.drive}' 2>/dev/null)" = nvme ] \
  && pass "waiting is running, nodeSelector fixed to drive=nvme" || fail "waiting is running, nodeSelector fixed to drive=nvme"
[ "$(kc dojo2 get node dojo2-worker -o jsonpath='{.metadata.labels.drive}' 2>/dev/null)" = nvme ] \
  && pass "Node labels unchanged" || fail "Node labels unchanged"

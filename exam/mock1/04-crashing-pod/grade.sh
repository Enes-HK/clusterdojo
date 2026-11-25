source /root/exam/bin/lib.sh
A=/home/student/answers/m1-04
log=$(on dojo1 "cat $A/previous.log 2>/dev/null")
echo "$log" | grep -q 'invoice-worker 3.1 starting' && echo "$log" | grep -q 'loading open invoices' && ! echo "$log" | grep -q 'waiting for jobs' \
  && pass "previous.log holds the crashed instance's output" || fail "previous.log holds the crashed instance's output"
t=$(on dojo1 "cat $A/termination 2>/dev/null" | tr -d '[:space:]')
[ "$t" = OOMKilled/137 ] && pass "Termination reason and exit code: OOMKilled/137" || fail "Termination reason and exit code: OOMKilled/137" "found: ${t:-nothing}"

kc dojo1 -n billing rollout status deploy/invoice-worker --timeout=30s >/dev/null 2>&1
d=$(kc dojo1 -n billing get deploy invoice-worker -o json 2>/dev/null)
c=$(echo "$d" | jq -c '.spec.template.spec.containers[] | select(.name=="worker")')
[ "$(echo "$c" | jq -r '.resources.requests.memory + "/" + .resources.limits.memory')" = 64Mi/128Mi ] \
  && pass "worker: memory request 64Mi, limit 128Mi" || fail "worker: memory request 64Mi, limit 128Mi" "$(echo "$c" | jq -c .resources)"
echo "$c" | jq -r '.command[2]' | grep -q 'head -c 40000000' && pass "Command unchanged" || fail "Command unchanged"
sleep 5
pod=$(live dojo1 billing app=invoice-worker | head -1)
p=$(kc dojo1 -n billing get pod "$pod" -o json 2>/dev/null)
[ "$(echo "$p" | jq -r '.status.containerStatuses[0].ready')/$(echo "$p" | jq -r '.status.containerStatuses[0].restartCount')" = true/0 ] \
  && kc dojo1 -n billing logs "$pod" 2>/dev/null | grep -q 'waiting for jobs' \
  && pass "The new Pod runs without restarts" || fail "The new Pod runs without restarts"

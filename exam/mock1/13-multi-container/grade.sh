source /root/exam/bin/lib.sh
kc dojo2 -n payroll rollout status deploy/payslip --timeout=30s >/dev/null 2>&1
dep=$(kc dojo2 -n payroll get deploy payslip -o json 2>/dev/null)
sp() { echo "$dep" | jq -r ".spec.template.spec$1" 2>/dev/null; }
[ "$(sp '.containers | map(.name) | sort | join(",")')" = app,log-forwarder ] && [ "$(sp '.initContainers | map(.name) | join(",")')" = prepare ] \
  && pass "Containers app + log-forwarder, init container prepare" || fail "Containers app + log-forwarder, init container prepare"
[ "$(sp '| [.volumes[]? | select(.emptyDir)] | length')" = 1 ] \
  && [ "$(sp '| [(.containers + .initContainers)[] | select(any(.volumeMounts[]?; .mountPath=="/shared"))] | length')" = 3 ] \
  && pass "All three containers mount one emptyDir at /shared" || fail "All three containers mount one emptyDir at /shared"

[ "$(kc dojo2 -n payroll get deploy payslip -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = 1 ] \
  && pass "Pod is Ready" || fail "Pod is Ready"

ex() { kc dojo2 -n payroll exec deploy/payslip -c app -- "$@" 2>/dev/null; }
[ "$(ex sh -c 'echo $PG_USER/$PG_PASSWORD')" = payroll_rw/t0p-s3cret-42 ] && pass "PG_USER and PG_PASSWORD come from the Secret" \
  || fail "PG_USER and PG_PASSWORD come from the Secret" "got: $(ex sh -c 'echo $PG_USER/$PG_PASSWORD')"
echo "$dep" | jq -e '[.spec.template.spec.containers[] | select(.name=="app") | .env[]? | select(.valueFrom.secretKeyRef.name=="pg-credentials")] | length == 2' >/dev/null \
  && pass "Both variables use secretKeyRef" || fail "Both variables use secretKeyRef"
[ "$(ex cat /etc/payroll.ini | tr -d '[:space:]')" = currency=EUR ] && ex test -f /etc/passwd \
  && pass "/etc/payroll.ini is a single file, rest of /etc still there" || fail "/etc/payroll.ini is a single file, rest of /etc still there"
[ "$(ex cat /shared/state.txt | tr -d '[:space:]')" = ready ] && pass "Init container wrote state.txt" || fail "Init container wrote state.txt"
probe=$(echo "$dep" | jq -r '.spec.template.spec.containers[] | select(.name=="app") | .readinessProbe')
echo "$probe" | jq -e '.exec.command | length >= 2 and (.[0]|test("sh$")) and (.[-1]|contains("grep -q ready /shared/state.txt"))' >/dev/null \
  && [ "$(echo "$probe" | jq -r .periodSeconds)" = 10 ] \
  && pass "Readiness probe runs the command through a shell every 10s" || fail "Readiness probe runs the command through a shell every 10s"
[ -n "$(kc dojo2 -n payroll logs deploy/payslip -c log-forwarder --tail=2 2>/dev/null)" ] && pass "log-forwarder prints the app log" || fail "log-forwarder prints the app log"

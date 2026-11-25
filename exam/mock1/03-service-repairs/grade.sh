source /root/exam/bin/lib.sh
get() { kc dojo2 -n support exec toolbox -- wget -qO- -T 3 "$1" 2>/dev/null | tr -d '[:space:]'; }

got=$(get helpdesk)
[ "$got" = helpdesk-ok ] && pass "Service helpdesk answers" || fail "Service helpdesk answers" "got: ${got:-no answer}"
[ "$(kc dojo2 -n support get deploy helpdesk -o json | jq -c '.spec.template.metadata.labels | to_entries | sort_by(.key) | map(.key+"="+.value)')" = '["app=helpdesk","version=v1"]' ] \
  && pass "Deployment helpdesk labels unchanged" || fail "Deployment helpdesk labels unchanged"

kc dojo2 -n support rollout status deploy/reporter --timeout=20s >/dev/null 2>&1
[ "$(kc dojo2 -n support get svc reporter -o json 2>/dev/null | jq -c '[.spec.selector, .spec.ports[0].port, .spec.ports[0].targetPort]')" = '[{"app":"reporter"},80,8080]' ] \
  && pass "Service reporter unchanged" || fail "Service reporter unchanged"
port=$(kc dojo2 -n support get deploy reporter -o json 2>/dev/null | jq -r '.spec.template.spec.containers[0].readinessProbe.httpGet.port // "none"')
[ "$port" = 8080 ] && pass "reporter keeps its readiness probe, now on port 8080" \
  || fail "reporter keeps its readiness probe, now on port 8080" "probe port: $port"
got=$(get reporter)
[ "$got" = reporter-ok ] && pass "Service reporter answers" || fail "Service reporter answers" "got: ${got:-no answer}"

ext=$(kc dojo2 -n support get svc warehouse-db -o json 2>/dev/null)
[ -n "$ext" ] && [ "$(echo "$ext" | jq -r '.spec.selector // {} | length')" = 0 ] && [ "$(echo "$ext" | jq -r '.spec.ports[0].port')" = 3306 ] \
  && pass "Service warehouse-db has no selector, port 3306" || fail "Service warehouse-db has no selector, port 3306"
ip=$(kc dojo2 -n external get pod remote-db -o jsonpath='{.status.podIP}')
es=$(kc dojo2 -n support get endpointslice warehouse-db-1 -o json 2>/dev/null)
[ "$(echo "$es" | jq -r '.metadata.labels["kubernetes.io/service-name"]')" = warehouse-db ] \
  && echo "$es" | jq -e --arg ip "$ip" '[.endpoints[].addresses[]] | index($ip)' >/dev/null \
  && [ "$(echo "$es" | jq -r '.ports[0].port')" = 9500 ] \
  && pass "EndpointSlice warehouse-db-1 points at the IP, port 9500" || fail "EndpointSlice warehouse-db-1 points at the IP, port 9500"
got=$(get warehouse-db:3306)
[ "$got" = warehouse-db-ok ] && pass "warehouse-db:3306 answers" || fail "warehouse-db:3306 answers" "got: ${got:-no answer}"

source /root/exam/bin/lib.sh
rel() { hc dojo2 -n "$1" ls -a -o json 2>/dev/null | jq -r --arg n "$2" ".[] | select(.name==\$n) | .$3"; }

f=$(on dojo2 "cat /home/student/answers/m2-06/jukebox-values.yaml 2>/dev/null")
echo "$f" | grep -q 'Live Now' && echo "$f" | grep -q 8090 && pass "jukebox's values saved" || fail "jukebox's values saved"

[ "$(rel streaming jukebox chart)" = webapp-1.2.0 ] && [ "$(rel streaming jukebox status)" = deployed ] \
  && pass "Release jukebox upgraded to webapp-1.2.0" || fail "Release jukebox upgraded to webapp-1.2.0" "chart: $(rel streaming jukebox chart)"
ready=$(kc dojo2 -n streaming get deploy jukebox -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
[ "$ready" = 3 ] && pass "jukebox runs 3 ready replicas" || fail "jukebox runs 3 ready replicas" "ready: ${ready:-0}"
kc dojo2 -n streaming get cm jukebox-banner -o jsonpath='{.data.index\.html}' 2>/dev/null | grep -q 'Live Now' \
  && [ "$(kc dojo2 -n streaming get svc jukebox -o jsonpath='{.spec.ports[0].port}' 2>/dev/null)" = 8090 ] \
  && pass "jukebox kept its values (banner and service.port)" || fail "jukebox kept its values (banner and service.port)"

kc dojo2 -n streaming rollout status deploy/broadcast --timeout=20s >/dev/null 2>&1
[ "$(kc dojo2 -n streaming get deploy broadcast -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)/$(kc dojo2 -n streaming get deploy broadcast -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" = nginx:1-alpine/1 ] \
  && pass "broadcast runs the working image again" || fail "broadcast runs the working image again"
hc dojo2 -n streaming history broadcast -o json 2>/dev/null | jq -e '.[-1].status=="deployed" and .[-1].revision==3 and (.[-1].description|test("Rollback to 1"))' >/dev/null \
  && pass "broadcast was rolled back to revision 1 with helm rollback" || fail "broadcast was rolled back to revision 1 with helm rollback"

[ "$(rel streaming-labs audiobook chart)" = webapp-1.0.0 ] && [ "$(rel streaming-labs audiobook status)" = deployed ] \
  && pass "Release audiobook installed with webapp-1.0.0 in streaming-labs" || fail "Release audiobook installed with webapp-1.0.0 in streaming-labs" "chart: $(rel streaming-labs audiobook chart)"
[ "$(kc dojo2 -n streaming-labs get svc audiobook -o jsonpath='{.spec.type}' 2>/dev/null)" = NodePort ] \
  && pass "audiobook Service is NodePort" || fail "audiobook Service is NodePort"

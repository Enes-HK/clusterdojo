source /root/exam/bin/lib.sh
np=$(kc dojo2 -n payments get networkpolicy payments-egress -o json 2>/dev/null)
[ -n "$np" ] && [ "$(kc dojo2 -n payments get networkpolicy --no-headers 2>/dev/null | wc -l)" = 1 ] \
  && pass "One NetworkPolicy payments-egress in payments" || fail "One NetworkPolicy payments-egress in payments"
echo "$np" | jq -e '.spec.podSelector == {} and .spec.policyTypes == ["Egress"]' >/dev/null \
  && pass "Selects all Pods, Egress only (incoming traffic unchanged)" || fail "Selects all Pods, Egress only (incoming traffic unchanged)" "$(echo "$np" | jq -c '{podSelector:.spec.podSelector, policyTypes:.spec.policyTypes}')"
echo "$np" | jq -e '[.spec.egress[]? | select(any(.to[]?; .ipBlock.cidr=="10.20.0.0/16" and (.ipBlock.except // [] | index("10.20.99.0/24")))
    and (.ports // []) == [{"port":443,"protocol":"TCP"}])] | length==1' >/dev/null \
  && pass "10.20.0.0/16 except 10.20.99.0/24 on TCP 443" || fail "10.20.0.0/16 except 10.20.99.0/24 on TCP 443"
echo "$np" | jq -e '[.spec.egress[]? | select(any(.to[]?; .ipBlock.cidr=="10.20.0.0/16")) | .to[] | select(.ipBlock.cidr != "10.20.0.0/16")] | length==0' >/dev/null \
  && pass "The partner rule allows only the partner network" || fail "The partner rule allows only the partner network"

sleep 3
from() { kc dojo2 -n payments exec deploy/api -- "$@" 2>/dev/null | tr -d '[:space:]'; }
get() { from wget -qO- -T 3 "http://$1"; }
kc dojo2 -n payments exec deploy/api -- nslookup -timeout=3 kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  && pass "DNS works" || fail "DNS works"
[ "$(get db.data:5432)" = db-ok ] && pass "api -> data/db:5432 allowed" || fail "api -> data/db:5432 allowed"
[ -z "$(get cache.data:6379)" ] && pass "api -> data/cache:6379 blocked" || fail "api -> data/cache:6379 blocked"
[ -z "$(get db.payments:5432)" ] && pass "api -> payments/db:5432 blocked (app=db, but not in data)" || fail "api -> payments/db:5432 blocked (app=db, but not in data)"
[ -z "$(get web.payments:8080)" ] && pass "api -> payments/web:8080 blocked" || fail "api -> payments/web:8080 blocked"
[ "$(probe dojo2 data busybox:1 app=probe -- wget -qO- -T 3 http://web.payments:8080 | tr -d '[:space:]')" = payments-web ] \
  && pass "Incoming traffic to payments still works" || fail "Incoming traffic to payments still works"

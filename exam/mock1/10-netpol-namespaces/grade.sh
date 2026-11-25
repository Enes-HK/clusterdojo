source /root/exam/bin/lib.sh
kc dojo1 -n treasury get networkpolicy engine-policy >/dev/null 2>&1 && pass "NetworkPolicy engine-policy exists" || fail "NetworkPolicy engine-policy exists"

ip() { live dojo1 "$1" app="$2" .status.podIP | head -1; }
CORE=$(ip treasury engine); STORE=$(ip treasury kvstore)
# reach <ns> <deploy> [container] <ip> <port> -> prints the answer or nothing
reach() { local ns=$1 d=$2 c=$3 to=$4 port=$5
  kc dojo1 -n "$ns" exec deploy/"$d" ${c:+-c $c} -- wget -qO- -T 3 "http://$to:$port" 2>/dev/null | tr -d '[:space:]'; }
ok()    { [ -n "$(reach "$@")" ]; }
allow() { local d=$1; shift; ok "$@" && pass "$d allowed" || fail "$d allowed"; }
block() { local d=$1; shift; ok "$@" && fail "$d blocked" || pass "$d blocked"; }

allow "dashboard/console -> engine:9000" dashboard console "" "$CORE" 9000
block "dashboard/console -> engine:9001" dashboard console "" "$CORE" 9001
block "dashboard/visitor -> engine:9000" dashboard visitor "" "$CORE" 9000
block "dashboard-staging/console -> engine:9000" dashboard-staging console "" "$CORE" 9000
allow "sre/alerts -> engine:9001" sre alerts "" "$CORE" 9001
block "sre/alerts -> engine:9000" sre alerts "" "$CORE" 9000
allow "treasury/reconciler -> engine:9000" treasury reconciler "" "$CORE" 9000
block "treasury/reconciler -> engine:9001" treasury reconciler "" "$CORE" 9001
allow "engine -> kvstore:11211" treasury engine tools "$STORE" 11211
block "engine -> kvstore:11212" treasury engine tools "$STORE" 11212
kc dojo1 -n treasury exec deploy/engine -c tools -- nslookup -timeout=3 kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  && pass "engine can still resolve DNS" || fail "engine can still resolve DNS"
ok dashboard visitor "" "$STORE" 11212 && pass "Other traffic unaffected (visitor -> kvstore:11212)" || fail "Other traffic unaffected (visitor -> kvstore:11212)"

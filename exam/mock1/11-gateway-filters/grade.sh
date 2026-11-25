source /root/exam/bin/lib.sh
r=$(kc dojo1 -n portal get httproute portal -o json 2>/dev/null)
echo "$r" | jq -e '(.spec.parentRefs[]? | select(.name=="portal-gw")) and .spec.hostnames == ["portal.local"]' >/dev/null \
  && pass "HTTPRoute portal attached to portal-gw for portal.local" || fail "HTTPRoute portal attached to portal-gw for portal.local"

ip=$(kc dojo1 -n portal get svc portal-gw-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
[ -n "$ip" ] && wait_for 30 on dojo1 "curl -s -m 2 -o /dev/null http://$ip/"
get() { on dojo1 "curl -s -m 5 -H 'Host: portal.local' http://$ip$1" | tr -d '\r' | sed 's/ *$//'; }
t() { local want=$1 path=$2 got; got=$(get "$path")
  [ "$got" = "$want" ] && pass "$path -> $want" || fail "$path -> $want" "got: ${got:-no answer}"; }

t "api path=/api/users x-env="      /old-api/users
t "api path=/api x-env="            /old-api
t "api path=/api/orders?x=1 x-env=prod" "/api/orders?x=1"
t web /
t web /about
h=$(on dojo1 "curl -s -m 5 -o /dev/null -w '%{http_code} %{redirect_url}' -H 'Host: portal.local' http://$ip/login")
echo "$h" | grep -Eqx '301 https://portal\.local(:443)?/login' && pass "/login -> 301 to https://portal.local/login" || fail "/login -> 301 to https://portal.local/login" "got: $h"
o=$(on dojo1 "curl -s -m 5 -H 'Host: other.local' http://$ip/" | tr -d '[:space:]')
[ "$o" != web ] && pass "Other hostnames aren't routed" || fail "Other hostnames aren't routed"

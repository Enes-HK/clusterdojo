source /root/exam/bin/lib.sh
g=$(kc dojo1 -n gateway-infra get gateway public -o json 2>/dev/null)
l() { echo "$g" | jq -r --arg n "$1" ".spec.listeners[]? | select(.name==\$n) | $2"; }
[ "$(echo "$g" | jq -r .spec.gatewayClassName)" = nginx ] && pass "Gateway public uses GatewayClass nginx" || fail "Gateway public uses GatewayClass nginx"
[ "$(l http .port)/$(l http .protocol)/$(l http .hostname)/$(l http .allowedRoutes.namespaces.from)" = '80/HTTP/*.example.org/All' ] \
  && pass "Listener http: 80, HTTP, *.example.org, routes from all Namespaces" || fail "Listener http: 80, HTTP, *.example.org, routes from all Namespaces"
[ "$(l https .port)/$(l https .protocol)/$(l https .hostname)/$(l https .allowedRoutes.namespaces.from)/$(l https '.tls.certificateRefs[0].name')" = '443/HTTPS/*.example.org/All/public-tls' ] \
  && pass "Listener https: 443, HTTPS, *.example.org, all Namespaces, Secret public-tls" || fail "Listener https: 443, HTTPS, *.example.org, all Namespaces, Secret public-tls"

r=$(kc dojo1 -n news get httproute news -o json 2>/dev/null)
echo "$r" | jq -e '.spec.parentRefs[]? | select(.name=="public" and .namespace=="gateway-infra")' >/dev/null \
  && pass "HTTPRoute news attached to Gateway public in gateway-infra" || fail "HTTPRoute news attached to Gateway public in gateway-infra"
echo "$r" | jq -e '.spec.hostnames == ["news.example.org"]' >/dev/null && pass "HTTPRoute hostname is news.example.org" || fail "HTTPRoute hostname is news.example.org"
echo "$r" | jq -e '[.spec.rules[]?.backendRefs[]? | select(.name=="main") | .weight] == [70]' >/dev/null \
  && echo "$r" | jq -e '[.spec.rules[]?.backendRefs[]? | select(.name=="preview") | .weight] == [30]' >/dev/null \
  && pass "Weights: main 70, preview 30" || fail "Weights: main 70, preview 30"

ip=$(kc dojo1 -n gateway-infra get svc public-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
# a new Gateway's NGINX Pod needs a while to start; any HTTP answer (even a 404) means it's up
[ -n "$ip" ] && wait_for 45 on dojo1 "curl -s -m 2 -o /dev/null http://$ip/"
get() { on dojo1 "curl -s -m 5 -H 'Host: ${3:-news.example.org}' http://$ip$1 ${2:+-H '$2'}" | tr -d '[:space:]'; }
t() { local want=$1 path=$2 hdr=$3 got; got=$(get "$path" "$hdr")
  [ "$got" = "$want" ] && pass "$path ${hdr:+[$hdr] }-> $want" || fail "$path ${hdr:+[$hdr] }-> $want" "got: ${got:-no answer}"; }

t catalog-beta /catalog       "X-Early-Access: true"
t catalog-beta /catalog/users "X-Early-Access: true"
t catalog      /catalog
t catalog      /catalog/users "X-Early-Access: false"
t status   /status
sub=$(get /status/deep)
{ [ "$sub" = main ] || [ "$sub" = preview ]; } && pass "/status/deep is not /status (goes to main/preview)" \
  || fail "/status/deep is not /status (goes to main/preview)" "got: ${sub:-no answer}"

out=$(on dojo1 "for i in \$(seq 40); do curl -s -m 3 -H 'Host: news.example.org' http://$ip/; done")
s=$(echo "$out" | grep -cx main); c=$(echo "$out" | grep -cx preview)
[ "$s" -gt "$c" ] && [ "$c" -gt 0 ] && pass "/ is split between main and preview" || fail "/ is split between main and preview" "main=$s preview=$c"

o=$(get / "" other.example.org); { [ "$o" != main ] && [ "$o" != preview ]; } && pass "Other hostnames aren't routed" || fail "Other hostnames aren't routed" "got: $o"
got=$(on dojo1 "curl -sk -m 5 --resolve news.example.org:443:$ip https://news.example.org/status" | tr -d '[:space:]')
[ "$got" = status ] && pass "HTTPS works: /status -> status" || fail "HTTPS works: /status -> status" "got: ${got:-no answer}"

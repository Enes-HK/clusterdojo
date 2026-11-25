source /root/exam/bin/lib.sh
g=$(kc dojo1 -n edge get gateway shared-gw -o json 2>/dev/null)
echo "$g" | jq -e '.spec.listeners | length==1 and .[0].allowedRoutes.namespaces == {"from":"Selector","selector":{"matchLabels":{"gateway-access":"granted"}}}' >/dev/null \
  && pass "Gateway shared-gw unchanged" || fail "Gateway shared-gw unchanged"
r=$(kc dojo1 -n storefront get httproute store -o json 2>/dev/null)
echo "$r" | jq -ce '[.spec.parentRefs, .spec.hostnames, [.spec.rules[].backendRefs[] | {name, namespace, port}]] == [[{"group":"gateway.networking.k8s.io","kind":"Gateway","name":"shared-gw","namespace":"edge"}],["store.local"],[{"name":"catalog-api","namespace":"backends","port":80}]]' >/dev/null \
  && pass "HTTPRoute store unchanged" || fail "HTTPRoute store unchanged"
[ "$(kc dojo1 get ns storefront -o jsonpath='{.metadata.labels.gateway-access}')" = granted ] \
  && pass "Namespace storefront labelled gateway-access=granted" || fail "Namespace storefront labelled gateway-access=granted"
st() { echo "$r" | jq -r --arg t "$1" '[.status.parents[]? | select(.parentRef.name=="shared-gw") | .conditions[] | select(.type==$t) | .status] | first // "none"'; }
r=$(kc dojo1 -n storefront get httproute store -o json 2>/dev/null)
[ "$(st Accepted)/$(st ResolvedRefs)" = True/True ] && pass "Route accepted, backend reference resolved" || fail "Route accepted, backend reference resolved" "Accepted=$(st Accepted) ResolvedRefs=$(st ResolvedRefs)"
kc dojo1 -n backends get referencegrant -o json | jq -e '
  [.items[] | select(any(.spec.from[]; .kind=="HTTPRoute" and .namespace=="storefront"))] as $g
  | ($g|length)>=1 and all($g[]; all(.spec.to[]; .kind=="Service" and .name=="catalog-api"))
  and ([.items[].spec.from[] | select(.namespace != "storefront" or .kind != "HTTPRoute")] | length)==0' >/dev/null \
  && pass "ReferenceGrant: HTTPRoutes from storefront to Service catalog-api only" || fail "ReferenceGrant: HTTPRoutes from storefront to Service catalog-api only"
ip=$(kc dojo1 -n edge get svc shared-gw-nginx -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
got=""; [ -n "$ip" ] && for _ in 1 2 3 4 5 6; do got=$(on dojo1 "curl -s -m 3 -H 'Host: store.local' http://$ip/" | tr -d '[:space:]'); [ "$got" = catalog-api-ok ] && break; sleep 2; done
[ "$got" = catalog-api-ok ] && pass "store.local reaches catalog-api" || fail "store.local reaches catalog-api" "got: ${got:-no answer}"

source /root/exam/bin/lib.sh
SA=system:serviceaccount:ci:deployer
can() { kc dojo4 auth can-i "$@" --as=$SA 2>/dev/null; }
ok=1; for v in get list create update delete; do [ "$(can $v deployments.apps -n apps-staging)" = yes ] || ok=0; done
[ $ok = 1 ] && pass "deployer can get, list, create, update, delete Deployments in apps-staging" || fail "deployer can get, list, create, update, delete Deployments in apps-staging"
[ "$(can get secrets -n apps-staging)" = no ] && [ "$(can list secrets -n apps-staging)" = no ] && [ "$(can patch deployments.apps -n apps-staging)" = no ] \
  && pass "Role grants nothing else (no Secrets, no patch)" || fail "Role grants nothing else (no Secrets, no patch)"
[ "$(can create deployments.apps -n default)" = no ] && pass "No rights outside apps-staging gained" || fail "No rights outside apps-staging gained"
[ "$(kc dojo4 get role,rolebinding -n apps-staging --no-headers 2>/dev/null | wc -l)" = 2 ] \
  && [ "$(kc dojo4 get clusterrolebinding -o json | jq '[.items[] | select(.subjects[]? | .name=="deployer" or .name=="system:serviceaccounts:ci")] | length')" = 0 ] \
  && pass "Only the existing Role and RoleBinding used" || fail "Only the existing Role and RoleBinding used"
a=$(on dojo4 "cat $ANS/m2-07/can-i 2>/dev/null" | tr -d '\r' | tr 'A-Z' 'a-z' | sed 's/^ *[0-9.)]* *//;s/ *$//' | sed '/^$/d' | paste -sd,)
[ "$a" = "yes,no,yes" ] && pass "can-i answers" || fail "can-i answers" "found: $a"

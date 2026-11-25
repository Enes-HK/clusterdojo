source /root/exam/bin/lib.sh
sec() { kc dojo3 -n kube-system get secret "bootstrap-token-$1" -o json 2>/dev/null; }
[ -z "$(sec zx81kd)" ] && pass "Leaked token zx81kd deleted" || fail "Leaked token zx81kd deleted"
[ -n "$(sec q7w2er)" ] && [ -n "$(sec h5n2b8)" ] && pass "Other tokens kept" || fail "Other tokens kept"
t=$(kc dojo3 -n kube-system get secret --field-selector type=bootstrap.kubernetes.io/token -o json \
  | jq -c '[.items[] | select((.data.description // "" | @base64d)=="worker-batch-3")] | last')
if [ "$t" = null ] || [ -z "$t" ]; then
  fail "New token with description worker-batch-3" "not found"; fail "New token expires after 2 hours"; fail "join.sh uses the new token"; fail "join.sh has the right CA cert hash"; exit 0
fi
pass "New token with description worker-batch-3"
ttl=$(echo "$t" | jq -r '((.data.expiration | @base64d | fromdate) - (.metadata.creationTimestamp | fromdate))')
[ "$ttl" -ge 7080 ] 2>/dev/null && [ "$ttl" -le 7320 ] && pass "New token expires after 2 hours" || fail "New token expires after 2 hours" "lifetime: ${ttl}s"
tok=$(echo "$t" | jq -r '(.data["token-id"] | @base64d) + "." + (.data["token-secret"] | @base64d)')
j=$(on dojo3 "cat $ANS/m2-08/join.sh 2>/dev/null" | tr -d '\r' | tr '\\\n' '  ')
echo "$j" | grep -Eq "kubeadm join [^ ]+:6443 .*--token $tok( |$)" && pass "join.sh uses the new token" || fail "join.sh uses the new token"
h=$(on dojo3 "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'")
echo "$j" | grep -q -- "--discovery-token-ca-cert-hash sha256:$h" && pass "join.sh has the right CA cert hash" || fail "join.sh has the right CA cert hash"

source /root/exam/bin/lib.sh
A=/home/student/answers/m1-07
on dojo1 "openssl pkey -in $A/dana.key -noout" >/dev/null 2>&1 && on dojo1 "openssl req -in $A/dana.csr -noout -subject" 2>/dev/null | grep -q 'CN *= *dana' \
  && pass "dana.key and dana.csr (CN dana) exist" || fail "dana.key and dana.csr (CN dana) exist"

csr=$(kc dojo1 get csr dana -o json 2>/dev/null)
echo "$csr" | jq -e '.spec.signerName=="kubernetes.io/kube-apiserver-client" and (.spec.usages|index("client auth")) and .spec.expirationSeconds==86400' >/dev/null \
  && pass "CSR dana: kube-apiserver-client signer, client auth, 86400 seconds" || fail "CSR dana: kube-apiserver-client signer, client auth, 86400 seconds"
echo "$csr" | jq -e '[.status.conditions[]? | select(.type=="Approved")] | length == 1' >/dev/null && pass "CSR dana approved" || fail "CSR dana approved"

on dojo1 "openssl verify -CAfile /etc/kubernetes/pki/ca.crt $A/dana.crt" >/dev/null 2>&1 \
  && on dojo1 "openssl x509 -in $A/dana.crt -noout -subject" | grep -q 'CN *= *dana' \
  && [ "$(on dojo1 "openssl x509 -in $A/dana.crt -noout -pubkey | sha256sum; openssl pkey -in $A/dana.key -pubout | sha256sum" | sort -u | wc -l)" = 1 ] \
  && pass "dana.crt is signed by the cluster CA and matches dana.key" || fail "dana.crt is signed by the cluster CA and matches dana.key"

kd() { on dojo1 "kubectl --kubeconfig $A/dana.kubeconfig $*" 2>/dev/null; }
[ "$(kd config current-context)" = dana@dojo1 ] && [ "$(kd config view --minify -o jsonpath='{..namespace}')" = dev ] \
  && pass "Current context dana@dojo1 with Namespace dev" || fail "Current context dana@dojo1 with Namespace dev"
[ "$(kd auth whoami -o jsonpath='{.status.userInfo.username}')" = dana ] && kd get pods | grep -q notes \
  && pass "kubectl with dana.kubeconfig works as dana" || fail "kubectl with dana.kubeconfig works as dana"

can() { kc dojo1 auth can-i "$@" --as=dana 2>/dev/null; }
[ "$(can get pods -n dev)$(can list pods -n dev)$(can create pods -n dev)$(can delete pods -n dev)" = yesyesyesyes ] \
  && pass "dana can get, list, create, delete Pods in dev" || fail "dana can get, list, create, delete Pods in dev"
[ "$(can get pods -n default)$(can create deployments -n dev)$(can get secrets -n dev)$(can update pods -n dev)" = nononono ] \
  && pass "dana can't do anything else" || fail "dana can't do anything else"
r=$(kc dojo1 -n dev get rolebinding dana-pod-editor -o json 2>/dev/null)
[ "$(echo "$r" | jq -r '.roleRef.kind + "/" + .roleRef.name')" = Role/pod-editor ] && echo "$r" | jq -e '.subjects[]? | select(.kind=="User" and .name=="dana")' >/dev/null \
  && pass "RoleBinding dana-pod-editor binds Role pod-editor to User dana" || fail "RoleBinding dana-pod-editor binds Role pod-editor to User dana"

source /root/exam/bin/lib.sh
ds=$(kc dojo3 -n kube-system get ds kube-proxy -o json 2>/dev/null)
nodes=$(kc dojo3 get nodes --no-headers 2>/dev/null | wc -l)
echo "$ds" | jq -e --argjson n "$nodes" '.status.desiredNumberScheduled==$n and ([.spec.template.spec.nodeSelector // {} | keys[] | select(startswith("node-role"))] | length)==0' >/dev/null \
  && pass "kube-proxy DaemonSet covers all $nodes nodes again" || fail "kube-proxy DaemonSet covers all $nodes nodes again" "desired: $(echo "$ds" | jq .status.desiredNumberScheduled)"
[ "$(kc dojo3 -n kube-system get pod -l k8s-app=kube-proxy --field-selector spec.nodeName=dojo3-control-plane -o jsonpath='{.items[0].status.phase}' 2>/dev/null)" = Running ] \
  && pass "kube-proxy runs on the control plane" || fail "kube-proxy runs on the control plane"
svc=$(kc dojo3 -n stock get svc inventory -o jsonpath='{.spec.selector.app}/{.spec.ports[0].port}/{.spec.ports[0].targetPort}' 2>/dev/null)
[ "$svc" = inventory/80/8080 ] && pass "Service inventory unchanged" || fail "Service inventory unchanged" "$svc"
sleep 3
[ "$(probe dojo3 stock busybox:1 app=check -- wget -qO- -T 3 http://inventory)" = inventory-ok ] \
  && pass "inventory answers on port 80" || fail "inventory answers on port 80"
[ "$(probe dojo3 stock busybox:1 app=check -- wget -qO- -T 3 http://catalog)" = catalog-ok ] \
  && pass "catalog still answers" || fail "catalog still answers"

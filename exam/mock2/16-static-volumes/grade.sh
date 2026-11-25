source /root/exam/bin/lib.sh

pv=$(kc dojo2 get pv records-pv -o json 2>/dev/null)
if [ -n "$pv" ]; then
  [ "$(echo "$pv" | jq -r .spec.hostPath.path)" = /mnt/records ] && [ "$(echo "$pv" | jq -r .spec.capacity.storage)" = 3Gi ] \
    && [ "$(echo "$pv" | jq -r '.spec.accessModes[0]')" = ReadWriteOnce ] \
    && pass "PV records-pv: 3Gi, RWO, hostPath /mnt/records" || fail "PV records-pv: 3Gi, RWO, hostPath /mnt/records"
  echo "$pv" | jq -e '[.spec.nodeAffinity.required.nodeSelectorTerms[].matchExpressions[] | select(.operator=="In") | .values[]] | index("dojo2-worker")' >/dev/null \
    && pass "PV restricted to dojo2-worker via nodeAffinity" || fail "PV restricted to dojo2-worker via nodeAffinity"
else
  fail "PV records-pv: 3Gi, RWO, hostPath /mnt/records"; fail "PV restricted to dojo2-worker via nodeAffinity"
fi

pvc=$(kc dojo2 -n records get pvc records-claim -o jsonpath='{.status.phase}/{.spec.volumeName}/{.spec.resources.requests.storage}' 2>/dev/null)
[ "$pvc" = "Bound/records-pv/2Gi" ] && pass "PVC records-claim requests 2Gi and is bound to records-pv" \
  || fail "PVC records-claim requests 2Gi and is bound to records-pv" "phase/volume/request: $pvc"

kc dojo2 -n records rollout status deploy/scanner --timeout=20s >/dev/null 2>&1
dep=$(kc dojo2 -n records get deploy scanner -o json 2>/dev/null)
vol=$(echo "$dep" | jq -r '.spec.template.spec.volumes[]? | select(.persistentVolumeClaim.claimName=="records-claim") | .name')
[ -n "$vol" ] && echo "$dep" | jq -e --arg v "$vol" '.spec.template.spec.containers[0].volumeMounts[]? | select(.name==$v and (.mountPath|test("^/data/?$")))' >/dev/null \
  && pass "Deployment scanner mounts records-claim at /data" || fail "Deployment scanner mounts records-claim at /data"
node=$(kc dojo2 -n records get pod -l app=scanner -o jsonpath='{.items[?(@.status.phase=="Running")].spec.nodeName}' 2>/dev/null | tr ' ' '\n' | sort -u | xargs)
[ "$node" = dojo2-worker ] && pass "scanner Pod running on dojo2-worker" || fail "scanner Pod running on dojo2-worker" "node: $node"
on dojo2-node1 "test -s /mnt/records/scan.log" && pass "scan.log written to /mnt/records on the node" \
  || fail "scan.log written to /mnt/records on the node"

pvc=$(kc dojo2 -n records get pvc buffer-claim -o jsonpath='{.status.phase}/{.spec.volumeName}/{.spec.resources.requests.storage}' 2>/dev/null)
[ "$pvc" = "Bound/premium-pv/600Mi" ] && pass "PVC buffer-claim (600Mi) is bound to premium-pv" \
  || fail "PVC buffer-claim (600Mi) is bound to premium-pv" "phase/volume/request: $pvc"

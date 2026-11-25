source /root/exam/bin/lib.sh
kc dojo1 -n logging rollout status deploy/ingest --timeout=30s >/dev/null 2>&1
s=$(kc dojo1 -n logging get deploy ingest -o json 2>/dev/null | jq '.spec.template.spec')

echo "$s" | jq -e '.volumes[]? | select(.name=="logs" and .emptyDir!=null)' >/dev/null \
  && echo "$s" | jq -e '.containers[] | select(.name=="app") | .volumeMounts[]? | select(.name=="logs" and .mountPath=="/var/log/app")' >/dev/null \
  && pass "emptyDir volume logs mounted at /var/log/app in app" || fail "emptyDir volume logs mounted at /var/log/app in app"

echo "$s" | jq -e '.initContainers[]? | select(.name=="shipper" and .restartPolicy=="Always" and .image=="busybox:1")' >/dev/null \
  && pass "shipper is a native sidecar (initContainer with restartPolicy Always)" \
  || fail "shipper is a native sidecar (initContainer with restartPolicy Always)"
echo "$s" | jq -e '.initContainers[]? | select(.name=="shipper") | .volumeMounts[]? | select(.name=="logs")' >/dev/null \
  && pass "shipper mounts the logs volume" || fail "shipper mounts the logs volume"

pod=$(live dojo1 logging app=ingest 'select(.status.phase=="Running") | .metadata.name' | head -1)
sleep 6
kc dojo1 -n logging logs "$pod" -c shipper --tail=5 2>/dev/null | grep -q 'ingest batch' \
  && pass "kubectl logs -c shipper shows the app log" || fail "kubectl logs -c shipper shows the app log"

conf=$(kc dojo1 -n logging exec "$pod" -c app -- cat /etc/app.conf 2>/dev/null)
echo "$conf" | grep -q 'batch_size=500' && pass "/etc/app.conf contains the ConfigMap key app.conf" \
  || fail "/etc/app.conf contains the ConfigMap key app.conf"
kc dojo1 -n logging exec "$pod" -c app -- test -f /etc/passwd 2>/dev/null \
  && ! kc dojo1 -n logging exec "$pod" -c app -- test -e /etc/unused.conf 2>/dev/null \
  && pass "/etc not replaced (subPath used)" || fail "/etc not replaced (subPath used)"

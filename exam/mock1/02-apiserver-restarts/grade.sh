source /root/exam/bin/lib.sh
m=/etc/kubernetes/manifests/kube-apiserver.yaml
probe_ports=$(on dojo4 "grep -A8 -E 'livenessProbe|readinessProbe|startupProbe' $m | grep -E '^\s+port:' | awk '{print \$2}' | sed 's/^probe-port$/6443/' | sort -u | tr '\n' ' '")
[ "$probe_ports" = "6443 " ] && pass "All kube-apiserver probes use the apiserver port (probe-port / 6443)" \
  || fail "All kube-apiserver probes use the apiserver port (probe-port / 6443)" "ports: $probe_ports"
on dojo4 "grep -q -- '--secure-port=6443' $m && grep -q -- '--etcd-servers=https://127.0.0.1:2379' $m" \
  && pass "Unrelated settings unchanged" || fail "Unrelated settings unchanged"

# stable = the same container survives longer than the liveness kill window (10s delay + 8 x 10s failures)
cid() { on dojo4 "crictl ps --name kube-apiserver -o json" | jq -r '.containers[0].id // ""'; }
r1=$(cid)
age=$(( $(date +%s) - $(on dojo4 "crictl inspect $r1" 2>/dev/null | jq -r '.status.createdAt' | xargs -I{} date -d {} +%s 2>/dev/null || date +%s) ))
[ "$age" -lt 130 ] && sleep $((130 - age))
r2=$(cid)
kc dojo4 get --raw=/livez >/dev/null 2>&1 && [ -n "$r1" ] && [ "$r1" = "$r2" ] \
  && pass "kube-apiserver running stable (same container for 2+ minutes)" \
  || fail "kube-apiserver running stable (same container for 2+ minutes)"

f=$(on dojo4 "tr -d '[:space:]' < /home/student/answers/m1-02/field 2>/dev/null")
echo "$f" | grep -qi 'livenessProbe' && echo "$f" | grep -qi 'port' && pass "field file names the livenessProbe port" \
  || fail "field file names the livenessProbe port" "found: $f"

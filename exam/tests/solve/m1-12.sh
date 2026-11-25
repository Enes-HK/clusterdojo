source /root/exam/bin/lib.sh
ip=$(kc dojo2 -n corp-dns get svc corp-resolver -o jsonpath='{.spec.clusterIP}')
cf=$(kc dojo2 -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')
printf '%s\ncorp.internal:53 {\n    errors\n    cache 30\n    forward . %s\n}\n' "$cf" "$ip" > /tmp/Corefile
kc dojo2 -n kube-system create cm coredns --from-file=Corefile=/tmp/Corefile --dry-run=client -o yaml | kc dojo2 apply -f -
# the kubelet syncs the ConfigMap into the Pods and the reload plugin picks it up (together up to ~2 min).
# Old "Reloading complete" lines are in the logs too, so wait until every CoreDNS Pod answers itself.
for _ in $(seq 20); do
  ips=$(kc dojo2 -n kube-system get pod -l k8s-app=kube-dns -o jsonpath='{.items[*].status.podIP}')
  probe dojo2 default busybox:1 app=dns-check -- sh -c "for i in $ips; do nslookup -timeout=3 build.ci.corp.internal \$i | grep -q 10.10.10.30 || exit 1; done" && break
  sleep 5
done

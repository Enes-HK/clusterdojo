source /root/exam/bin/lib.sh
kc dojo2 -n kube-system patch deploy metrics-server --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
kc dojo2 -n kube-system rollout status deploy/metrics-server --timeout=180s
# right after the fix, top can list only some of the Pods: wait until all three have metrics, then one more scrape
wait_for 180 bash -c "[ \$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo2 -n analytics top pods --no-headers 2>/dev/null | wc -l) = 3 ]"
sleep 20
kc dojo2 -n analytics top pods --sort-by=memory
top=$(kc dojo2 -n analytics top pods --sort-by=memory --no-headers | head -1 | awk '{print $1}')
echo "$top" | put dojo2 $ANS/m2-04/top-pod

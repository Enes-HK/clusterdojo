source /root/exam/bin/lib.sh
kc dojo3 -n kube-system patch ds kube-proxy --type=json -p '[{"op":"replace","path":"/spec/template/spec/nodeSelector","value":{"kubernetes.io/os":"linux"}}]'
wait_for 90 bash -c "[ \"\$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 -n kube-system get pod -l k8s-app=kube-proxy --field-selector spec.nodeName=dojo3-control-plane -o jsonpath='{.items[0].status.phase}')\" = Running ]"
sleep 5

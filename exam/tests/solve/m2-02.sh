source /root/exam/bin/lib.sh
on dojo4 "sed -i 's#- --kubeconfig=/etc/kubernetes/kube-scheduler.conf#- --kubeconfig=/etc/kubernetes/scheduler.conf#' /etc/kubernetes/manifests/kube-scheduler.yaml"
wait_for 120 bash -c "[ \"\$(kubectl --kubeconfig $EXAM/kubeconfigs/dojo4 -n kube-system get pod kube-scheduler-dojo4-control-plane -o jsonpath='{.status.conditions[?(@.type==\"Ready\")].status}')\" = True ]"
kc dojo4 -n jobs rollout status deploy/queue-worker --timeout=120s

source /root/exam/bin/lib.sh
drop_ns dojo4 jobs
# the scheduler reads a kubeconfig that doesn't exist, so it exits right after starting
on dojo4 "sed -i 's#- --kubeconfig=/etc/kubernetes/scheduler.conf#- --kubeconfig=/etc/kubernetes/kube-scheduler.conf#' /etc/kubernetes/manifests/kube-scheduler.yaml"
sleep 15
wait_for 120 bash -c "! ssh dojo4 \"crictl ps --name '^kube-scheduler\$' -q\" | grep -q ."
kc dojo4 create ns jobs
kc dojo4 -n jobs create deploy queue-worker --image=busybox:1 --replicas=2 -- sleep 1d

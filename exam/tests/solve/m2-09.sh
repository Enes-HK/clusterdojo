source /root/exam/bin/lib.sh
on dojo1-node1 'grep -rls "name: node-debugger" /etc/kubelet.d | xargs -r rm -v'
wait_for 60 bash -c "! kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n default get pod node-debugger-dojo1-worker"

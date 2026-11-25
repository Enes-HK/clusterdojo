source /root/exam/bin/lib.sh
# kubelet points at a binary path that doesn't exist, and the service is disabled
on dojo3-node1 "sed -i 's#^ExecStart=/usr/bin/kubelet #ExecStart=/usr/local/bin/kubelet #' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf \
  && systemctl daemon-reload && systemctl disable kubelet && systemctl stop kubelet"
wait_for 90 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get node dojo3-worker | grep -q NotReady"
kc dojo3 get nodes

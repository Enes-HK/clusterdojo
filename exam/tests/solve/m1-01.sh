source /root/exam/bin/lib.sh
on dojo3-node1 "sed -i 's#/usr/local/bin/kubelet#/usr/bin/kubelet#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf && systemctl daemon-reload && systemctl enable --now kubelet"
wait_for 90 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get node dojo3-worker --no-headers | grep -qw Ready"

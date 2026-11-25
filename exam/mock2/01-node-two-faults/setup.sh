source /root/exam/bin/lib.sh
kc dojo3 delete pod worker-probe --ignore-not-found --force --grace-period=0
answers dojo3 m2-01
# 203/EXEC first (wrong binary path), then, once that's fixed, 1/FAILURE (config file path with a typo)
on dojo3-node1 "f=/etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  sed -i -e 's#^ExecStart=/usr/sbin/kubelet #ExecStart=/usr/bin/kubelet #' -e 's#--config=/var/lib/kubelet/config.yml#--config=/var/lib/kubelet/config.yaml#' \$f
  sed -i -e 's#^ExecStart=/usr/bin/kubelet #ExecStart=/usr/sbin/kubelet #' -e 's#--config=/var/lib/kubelet/config.yaml#--config=/var/lib/kubelet/config.yml#' \$f
  systemctl daemon-reload && systemctl restart kubelet; true"
wait_for 90 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get node dojo3-worker | grep -q NotReady"
kc dojo3 get nodes

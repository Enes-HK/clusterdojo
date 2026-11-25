source /root/exam/bin/lib.sh
on dojo3-node1 "sed -i -e 's#^ExecStart=/usr/sbin/kubelet #ExecStart=/usr/bin/kubelet #' -e 's#--config=/var/lib/kubelet/config.yml#--config=/var/lib/kubelet/config.yaml#' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf && systemctl daemon-reload && systemctl enable --now kubelet && systemctl restart kubelet"
wait_for 90 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get node dojo3-worker --no-headers | grep -qw Ready"
on dojo3 "echo 203/EXEC > /home/student/answers/m2-01/status"
kc dojo3 apply -f - <<'Y'
apiVersion: v1
kind: Pod
metadata: {name: worker-probe}
spec:
  nodeName: dojo3-worker
  containers: [{name: worker-probe, image: "nginx:1-alpine"}]
Y
kc dojo3 wait pod worker-probe --for=condition=Ready --timeout=90s

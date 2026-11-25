#!/bin/bash
# Undoes every fault a task can leave behind, so the next mock starts from clean clusters:
# kubelet drop-in and config, control plane manifests, kube-proxy, metrics-server, CoreDNS config, cordoned nodes.
# Uses the originals that setup-all.sh saved (/root/.dojo on each node, state/coredns-*.yaml).
source /root/exam/bin/lib.sh
cd "$EXAM" || exit 1

for h in dojo1-node1 dojo1-node2 dojo2-node1 dojo3-node1 dojo1 dojo2 dojo3 dojo4; do
  on "$h" 'b=/root/.dojo; [ -f $b/10-kubeadm.conf ] || exit 0
    d=/etc/systemd/system/kubelet.service.d/10-kubeadm.conf; c=/var/lib/kubelet/config.yaml; r=0
    cmp -s $b/10-kubeadm.conf $d || { cp $b/10-kubeadm.conf $d; r=1; }
    cmp -s $b/kubelet-config.yaml $c || { cp $b/kubelet-config.yaml $c; r=1; }
    [ -d /etc/kubelet.d ] && { rm -rf /etc/kubelet.d; r=1; }
    if [ -d $b/manifests ]; then
      # a node that was stopped and started can come back with a new IP: kind rewrites the live manifests on boot,
      # so the saved copies have to follow, or they would point etcd and the API server at the old address
      new=$(cat /kind/old-ipv4 2>/dev/null); old=$(grep -o "advertise-address=[0-9.]*" $b/manifests/kube-apiserver.yaml | cut -d= -f2)
      if [ -n "$new" ] && [ -n "$old" ] && [ "$old" != "$new" ]; then sed -i -E "s/${old//./\\.}([^0-9]|$)/$new\1/g" $b/manifests/*.yaml; fi
      for f in $b/manifests/*.yaml; do cmp -s $f /etc/kubernetes/manifests/${f##*/} || cp $f /etc/kubernetes/manifests/; done
    fi
    systemctl daemon-reload; systemctl enable -q kubelet
    if [ $r = 1 ] || ! systemctl is-active -q kubelet; then systemctl restart kubelet; fi' || echo "heal: $h not reachable"
done

for c in dojo1 dojo2 dojo3 dojo4; do
  wait_for 180 kc "$c" get --raw=/readyz || echo "heal: $c API server not ready"
  kc "$c" -n kube-system patch ds kube-proxy --type=json \
    -p '[{"op":"replace","path":"/spec/template/spec/nodeSelector","value":{"kubernetes.io/os":"linux"}}]' >/dev/null 2>&1
  if [ -s "state/coredns-$c.yaml" ] && [ "$(kc "$c" -n kube-system get cm coredns -o jsonpath='{.data.Corefile}')" != "$(cat "state/coredns-$c.yaml")" ]; then
    kc "$c" -n kube-system create cm coredns --from-file=Corefile="state/coredns-$c.yaml" --dry-run=client -o yaml | kc "$c" apply -f - >/dev/null
    kc "$c" -n kube-system rollout restart deploy/coredns >/dev/null
  fi
  for n in $(kc "$c" get nodes -o jsonpath='{.items[?(@.spec.unschedulable==true)].metadata.name}'); do kc "$c" uncordon "$n" >/dev/null; done
done

# metrics-server on dojo2 needs --kubelet-insecure-tls (kind's kubelet serving certs aren't signed by the cluster CA)
if ! kc dojo2 -n kube-system get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q kubelet-insecure-tls; then
  kc dojo2 -n kube-system patch deploy metrics-server --type=json \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' >/dev/null
fi

for c in dojo1 dojo2 dojo3 dojo4; do
  wait_for 120 bash -c "! kubectl --kubeconfig $EXAM/kubeconfigs/$c get nodes --no-headers | grep -qv ' Ready'" || echo "heal: $c has nodes that aren't Ready"
done
kc dojo2 -n kube-system rollout status deploy/metrics-server --timeout=120s >/dev/null || echo "heal: metrics-server not ready"

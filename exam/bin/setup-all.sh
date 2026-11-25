#!/bin/bash
# Prepares freshly created clusters: node shells, add-ons, chart repo, clean-state backups, then the selected mock.
source /root/exam/bin/lib.sh
cd "$EXAM" || exit 1
mkdir -p state
log() { echo "[setup $(date +%T)] $*"; }

HOSTS="dojo1 dojo1-node1 dojo1-node2 dojo2 dojo2-node1 dojo3 dojo3-node1 dojo4"
CONTROL_PLANES="dojo1 dojo2 dojo3 dojo4"

log "waiting for sshd on all instances"
for h in $HOSTS; do wait_for 60 on "$h" true || { echo "cannot ssh to $h"; exit 1; }; done

log "preparing instances"
for h in $HOSTS; do
  # /root/.dojo keeps each node's original kubelet setup; bin/heal.sh puts it back before a mock is prepared
  on "$h" "echo $h > /etc/exam-name; mkdir -p $ANS /root/.dojo && chown student:student $ANS
    [ -f /root/.dojo/10-kubeadm.conf ] || cp /etc/systemd/system/kubelet.service.d/10-kubeadm.conf /root/.dojo/
    [ -f /root/.dojo/kubelet-config.yaml ] || cp /var/lib/kubelet/config.yaml /root/.dojo/kubelet-config.yaml"
done
for c in $CONTROL_PLANES; do
  on "$c" "cp /etc/kubernetes/admin.conf /home/student/.kube/config && chown -R student:student /home/student/.kube
    [ -d /root/.dojo/manifests ] || cp -r /etc/kubernetes/manifests /root/.dojo/manifests"
  # the original CoreDNS config, for the same reason
  [ -s "state/coredns-$c.yaml" ] || kc "$c" -n kube-system get cm coredns -o jsonpath='{.data.Corefile}' > "state/coredns-$c.yaml"
done

log "building helm chart repo"
rm -rf charts-repo/* && mkdir -p charts-repo
for v in charts-src/[0-9]*/; do helm package "$v"webapp -d charts-repo >/dev/null; done
helm repo index charts-repo --url http://charts.acme:8879

log "installing Gateway API + NGINX Gateway Fabric on dojo1"
kc dojo1 apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml >/dev/null
kc dojo1 apply --server-side -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.8.0/deploy/crds.yaml >/dev/null
kc dojo1 apply -f https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.8.0/deploy/nodeport/deploy.yaml >/dev/null
kc dojo1 -n nginx-gateway rollout status deploy/nginx-gateway --timeout=300s

log "installing metrics-server on dojo2"
kc dojo2 apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml >/dev/null
kc dojo2 -n kube-system patch deploy metrics-server --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' >/dev/null

log "copying etcdctl/etcdutl onto the control planes"
# kind nodes don't ship the etcd tools: copy them out of the running etcd container
for c in $CONTROL_PLANES; do
  on "$c" 'pid=$(crictl inspect $(crictl ps --name "^etcd$" -q) | jq -r .info.pid)
    cp /proc/$pid/root/usr/local/bin/etcdctl /proc/$pid/root/usr/local/bin/etcdutl /usr/local/bin/'
done

# SKIP_QUESTIONS=1: prepare the clusters only (the test harness sets up one task at a time)
[ -n "$SKIP_QUESTIONS" ] && { date > state/setup-done; log "done (tasks skipped)"; exit 0; }

bash "$EXAM/bin/prepare-mock.sh" "$(cat state/mock.txt 2>/dev/null || echo 1)"

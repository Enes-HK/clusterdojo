source /root/exam/bin/lib.sh
answers dojo3 m2-08
# all tokens of earlier runs (and kubeadm's own from cluster creation) go, then three known ones are added
kc dojo3 -n kube-system delete secret --field-selector type=bootstrap.kubernetes.io/token
on dojo3 'kubeadm token create q7w2er.8k3m9x4v1b6n0p5z --ttl 0 --description "node autoscaler, do not delete" >/dev/null
  kubeadm token create zx81kd.4hf7q2m9w0t3c6ya --ttl 48h --description "pasted into #general chat by mistake" >/dev/null
  kubeadm token create h5n2b8.r1t6y9u3i0o4p7as --ttl 24h --description "bootstrap for worker-batch-2" >/dev/null
  kubeadm token list'

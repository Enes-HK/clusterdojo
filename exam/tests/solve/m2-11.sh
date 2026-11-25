source /root/exam/bin/lib.sh
kc dojo2 apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: payments-egress, namespace: payments}
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]
    to:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}}
      podSelector: {matchLabels: {k8s-app: kube-dns}}
  - ports: [{protocol: TCP, port: 5432}]
    to:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: data}}
      podSelector: {matchLabels: {app: db}}
  - ports: [{protocol: TCP, port: 443}]
    to:
    - ipBlock: {cidr: 10.20.0.0/16, except: [10.20.99.0/24]}
EOF
sleep 5

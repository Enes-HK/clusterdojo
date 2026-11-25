source /root/exam/bin/lib.sh
kc dojo1 apply -f - <<'Y'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: engine-policy, namespace: treasury}
spec:
  podSelector: {matchLabels: {app: engine}}
  policyTypes: [Ingress, Egress]
  ingress:
  - from:
    - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: dashboard}}
      podSelector: {matchLabels: {app: console}}
    ports: [{port: 9000, protocol: TCP}]
  - from: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: sre}}}]
    ports: [{port: 9001, protocol: TCP}]
  - from: [{podSelector: {matchLabels: {app: reconciler}}}]
    ports: [{port: 9000, protocol: TCP}]
  egress:
  - to: [{podSelector: {matchLabels: {app: kvstore}}}]
    ports: [{port: 11211, protocol: TCP}]
  - ports: [{port: 53, protocol: UDP}, {port: 53, protocol: TCP}]
Y
sleep 5

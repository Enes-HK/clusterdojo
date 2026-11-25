source /root/exam/bin/lib.sh
kc dojo1 -n cdn patch deploy edge-cache --type merge -p '{"spec":{"replicas":6,"template":{"spec":{"nodeSelector":null,"topologySpreadConstraints":[{"maxSkew":1,"topologyKey":"topology.kubernetes.io/zone","whenUnsatisfiable":"DoNotSchedule","labelSelector":{"matchLabels":{"app":"edge-cache"}},"matchLabelKeys":["pod-template-hash"]}]}}}}'
kc dojo1 -n cdn rollout status deploy/edge-cache --timeout=180s

source /root/exam/bin/lib.sh
kc dojo2 -n platform patch deploy agent --type=strategic -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"maintenance","operator":"Equal","value":"planned","effect":"NoExecute","tolerationSeconds":300}]}}}}'
kc dojo2 -n platform get pod batch-runner -o json | jq 'del(.spec.schedulerName, .status, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp)' \
  | kc dojo2 replace --force -f -
kc dojo2 -n platform patch deploy waiting -p '{"spec":{"template":{"spec":{"nodeSelector":{"drive":"nvme"}}}}}'
kc dojo2 -n platform rollout status deploy/agent --timeout=90s
kc dojo2 -n platform rollout status deploy/waiting --timeout=90s
kc dojo2 -n platform wait pod batch-runner --for=condition=Ready --timeout=90s

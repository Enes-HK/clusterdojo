source /root/exam/bin/lib.sh
kc dojo1 -n warehouse patch pdb stock-api -p '{"spec":{"minAvailable":2}}'
kc dojo1 -n warehouse get pod legacy-report -o json | jq 'del(.spec.nodeName, .status, .metadata.uid, .metadata.resourceVersion, .metadata.creationTimestamp, .metadata.managedFields)' > /tmp/legacy-report.json
kc dojo1 drain dojo1-worker2 --ignore-daemonsets --delete-emptydir-data --force --timeout=240s
kc dojo1 apply -f /tmp/legacy-report.json
kc dojo1 -n warehouse wait pod legacy-report --for=condition=Ready --timeout=90s
kc dojo1 -n warehouse rollout status deploy/stock-api --timeout=120s

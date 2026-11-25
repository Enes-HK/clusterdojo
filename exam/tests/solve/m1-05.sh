source /root/exam/bin/lib.sh
A=/home/student/answers/m1-05
id=$(on dojo3 "grep -o 'container [0-9a-f]*' /var/log/disk-alert.log | cut -d' ' -f2")
on dojo3 "crictl inspect $id" | jq -r '.status.labels | "\(.["io.kubernetes.pod.namespace"])/\(.["io.kubernetes.pod.name"])/\(.["io.kubernetes.container.name"])"' | put dojo3 $A/owner
kc dojo3 -n ops-tools get pod audit-sync -o jsonpath='{.spec.containers[?(@.name=="uploader")].image}' | put dojo3 $A/image

source /root/exam/bin/lib.sh
kc dojo3 get ns reports -o jsonpath='{.status.conditions[?(@.type=="NamespaceContentRemaining")].message}{"\n"}'
fin=$(kc dojo3 -n reports get reportjobs -o json | jq -r '.items[].metadata.finalizers[]?' | head -1)
kc dojo3 -n reports patch reportjob quarterly --type=merge -p '{"metadata":{"finalizers":null}}'
echo "$fin" | put dojo3 /home/student/answers/m1-09/finalizer
wait_for 60 bash -c "! kubectl --kubeconfig $EXAM/kubeconfigs/dojo3 get ns reports"

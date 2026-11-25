source /root/exam/bin/lib.sh
kc dojo2 delete cm snapshot-canary --ignore-not-found
kc dojo2 create cm snapshot-canary --from-literal=note="present in a real snapshot"
answers dojo2 m1-06
on dojo2 "etcdctl version | head -1"

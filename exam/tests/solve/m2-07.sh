source /root/exam/bin/lib.sh
kc dojo4 -n apps-staging patch role deployer --type=json -p '[{"op":"replace","path":"/rules","value":[{"apiGroups":["apps"],"resources":["deployments"],"verbs":["get","list","create","update","delete"]}]}]'
kc dojo4 -n apps-staging patch rolebinding deployer --type=json -p '[{"op":"replace","path":"/subjects/0/namespace","value":"ci"}]'
printf 'yes\nno\nyes\n' | put dojo4 $ANS/m2-07/can-i

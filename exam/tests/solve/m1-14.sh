source /root/exam/bin/lib.sh
echo "nginx patch update" | put dojo1 $ANS/m1-14/broken-change
kc dojo1 -n shop rollout resume deploy/checkout
kc dojo1 -n shop rollout undo deploy/checkout --to-revision=2
kc dojo1 -n shop patch deploy checkout -p '{"spec":{"revisionHistoryLimit":4,"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
kc dojo1 -n shop rollout status deploy/checkout --timeout=120s

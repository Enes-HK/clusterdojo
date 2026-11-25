source /root/exam/bin/lib.sh
cj=$(kc dojo1 -n reports get cronjob nightly-export -o json 2>/dev/null)
f() { echo "$cj" | jq -r "$1"; }
[ "$(f .spec.concurrencyPolicy)" = Forbid ] && pass "concurrencyPolicy Forbid" || fail "concurrencyPolicy Forbid" "$(f .spec.concurrencyPolicy)"
[ "$(f .spec.successfulJobsHistoryLimit)/$(f .spec.failedJobsHistoryLimit)" = 2/1 ] && pass "Keeps 2 successful and 1 failed Job" || fail "Keeps 2 successful and 1 failed Job"
[ "$(f .spec.startingDeadlineSeconds)" = 300 ] && pass "startingDeadlineSeconds 300" || fail "startingDeadlineSeconds 300"
[ "$(f .spec.jobTemplate.spec.activeDeadlineSeconds)" = 120 ] && pass "Job activeDeadlineSeconds 120" || fail "Job activeDeadlineSeconds 120"
[ "$(f .spec.jobTemplate.spec.backoffLimit)" = 2 ] && pass "Job backoffLimit 2" || fail "Job backoffLimit 2"
[ "$(f '.spec.schedule')" = "30 2 * * *" ] && [ "$(f '.spec.jobTemplate.spec.template.spec.containers[0].image')" = busybox:1 ] \
  && pass "Schedule and container unchanged" || fail "Schedule and container unchanged"
j=$(kc dojo1 -n reports get job export-manual -o json 2>/dev/null)
echo "$j" | jq -e '(.metadata.ownerReferences[]? | select(.kind=="CronJob" and .name=="nightly-export")) and .spec.activeDeadlineSeconds==120 and .spec.backoffLimit==2' >/dev/null \
  && pass "Job export-manual created from the changed CronJob" || fail "Job export-manual created from the changed CronJob"
echo "$j" | jq -e '.status.succeeded==1' >/dev/null && pass "export-manual succeeded" || fail "export-manual succeeded"
l=$(on dojo1 "cat $ANS/m2-15/export.log 2>/dev/null")
echo "$l" | grep -q '^export started' && echo "$l" | grep -q 'export finished: 1284 rows' && pass "export.log holds the Pod's output" || fail "export.log holds the Pod's output"

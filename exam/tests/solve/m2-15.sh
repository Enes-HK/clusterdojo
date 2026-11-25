source /root/exam/bin/lib.sh
kc dojo1 -n reports patch cronjob nightly-export --type=merge -p '{"spec":{"concurrencyPolicy":"Forbid","successfulJobsHistoryLimit":2,"failedJobsHistoryLimit":1,"startingDeadlineSeconds":300,"jobTemplate":{"spec":{"activeDeadlineSeconds":120,"backoffLimit":2}}}}'
kc dojo1 -n reports create job export-manual --from=cronjob/nightly-export
kc dojo1 -n reports wait job export-manual --for=condition=Complete --timeout=90s
kc dojo1 -n reports logs job/export-manual | put dojo1 $ANS/m2-15/export.log

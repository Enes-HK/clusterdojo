---
title: Tame a CronJob
host: dojo1
docs: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/ | CronJob ; https://kubernetes.io/docs/concepts/workloads/controllers/job/ | Jobs
---
> Target: 6 minutes

CronJob `nightly-export` in Namespace `reports` sometimes overlaps with itself and leaves many old Jobs behind.

1. Change `nightly-export` so that:
    - a new run is skipped while the previous one is still running,
    - only the last 2 successful and the last 1 failed Jobs are kept,
    - a run that couldn't start within 5 minutes of its scheduled time is skipped,
    - a run is stopped after 2 minutes at most,
    - a failing run is retried at most 2 times.
2. **After** that change, start one run of `nightly-export` by hand as a Job named `export-manual`, and write the log output of its Pod into `/home/student/answers/m2-15/export.log`.

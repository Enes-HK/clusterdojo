**What this tests:** the CronJob fields versus the Job fields inside `jobTemplate`, and starting a Job from a CronJob.

```bash
k -n reports edit cronjob nightly-export
```

```yaml
spec:
  schedule: "30 2 * * *"
  concurrencyPolicy: Forbid             # skip a run while the previous one is running
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  startingDeadlineSeconds: 300          # missed by more than 5 minutes: skip it
  jobTemplate:
    spec:
      activeDeadlineSeconds: 120        # the Job is stopped after 2 minutes
      backoffLimit: 2                   # at most 2 retries
      template:
        ...
```

The first four belong to the CronJob. `activeDeadlineSeconds` and `backoffLimit` are Job fields, so they go under `jobTemplate.spec`, not into the Pod spec.

```bash
k -n reports create job export-manual --from=cronjob/nightly-export
k -n reports wait job export-manual --for=condition=Complete --timeout=60s
k -n reports logs job/export-manual > /home/student/answers/m2-15/export.log
cat /home/student/answers/m2-15/export.log
```

**Traps**
- `--from` copies the jobTemplate as it is at that moment. A Job created before the change doesn't get the new limits.
- `concurrencyPolicy: Replace` would stop the running Job and start the new one. The task wants the new run skipped.
- `activeDeadlineSeconds` in the Pod spec (`template.spec`) also exists, but it limits each Pod, not the whole Job.

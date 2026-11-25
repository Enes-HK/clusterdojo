**What this tests:** `kubectl drain` and what can stop it: Pods without a controller, `emptyDir` data, and PodDisruptionBudgets.

```bash
k -n warehouse get pod -o wide                 # everything on dojo1-worker2
k -n warehouse get pdb                         # stock-api  MIN AVAILABLE 3  ALLOWED DISRUPTIONS 0
```

With `minAvailable: 3` and 3 replicas no Pod may ever be evicted, and a drain would wait forever. "At least 2 available" is `minAvailable: 2`:

```bash
k -n warehouse patch pdb stock-api -p '{"spec":{"minAvailable":2}}'
k -n warehouse get pdb                         # ALLOWED DISRUPTIONS 1
```

`legacy-report` has no controller, so a drain deletes it and nothing brings it back. Save it first:

```bash
k -n warehouse get pod legacy-report -o yaml > legacy-report.yaml
```

```bash
k drain dojo1-worker2 --ignore-daemonsets --delete-emptydir-data --force
```

- `--ignore-daemonsets`: DaemonSet Pods (kube-proxy, kindnet) stay.
- `--delete-emptydir-data`: `stock-api` uses an `emptyDir`, whose content is lost on eviction.
- `--force`: needed for Pods without a controller (`legacy-report`).

The drain evicts the `stock-api` Pods one at a time, each time waiting until the replacement on `dojo1-worker` is ready. Then recreate the bare Pod without the old node name:

```bash
vi legacy-report.yaml                          # remove spec.nodeName, status, uid, resourceVersion, creationTimestamp
k apply -f legacy-report.yaml
k -n warehouse get pod -o wide                 # all on dojo1-worker
k get node                                     # dojo1-worker2  Ready,SchedulingDisabled
```

**Traps**
- `nodeName` in the saved YAML pins the Pod to the drained node again. A cordon doesn't stop that, because `nodeName` skips the scheduler.
- `maxUnavailable: 1` gives the same result for 3 replicas. Setting both fields is not allowed.

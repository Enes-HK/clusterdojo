**What this tests:** what a toleration really does, who schedules a Pod, and how to read a scheduling failure.

**1. Stay for a while after a NoExecute taint.** A `NoExecute` taint evicts running Pods that don't tolerate it. A toleration with `tolerationSeconds` lets the Pod stay for that long, then it's evicted anyway. Nothing about the node changes, so you only edit the Deployment:

```bash
k -n platform edit deploy agent
```

```yaml
    spec:
      tolerations:
      - key: maintenance
        operator: Equal
        value: planned
        effect: NoExecute
        tolerationSeconds: 300
      containers:
      - name: agent
        ...
```

**2. Pending without events.** "No events at all" means no scheduler ever looked at the Pod. The default scheduler only takes Pods whose `schedulerName` is `default-scheduler`:

```bash
k -n platform describe pod batch-runner | tail -3        # Events: <none>
k -n platform get pod batch-runner -o jsonpath='{.spec.schedulerName}'   # low-latency-scheduler
k -n kube-system get pods | grep scheduler               # only kube-scheduler exists
```

`schedulerName` can't be changed on an existing Pod, so save it, fix it, and create it again:

```bash
k -n platform get pod batch-runner -o yaml > batch-runner.yaml
vim batch-runner.yaml       # delete the schedulerName line (or set default-scheduler), remove status
k -n platform replace --force -f batch-runner.yaml
k -n platform get pod batch-runner -o wide
```

**3. The waiting Pod.** Here the scheduler did look, and it says exactly what's wrong:

```bash
k -n platform describe pod -l app=waiting | tail -5       # didn't match Pod's node affinity/selector
k get nodes -L drive                                      # the worker has drive=nvme
k -n platform edit deploy waiting                         # nodeSelector: drive: nvme
k -n platform get pod -l app=waiting -o wide
```

**Traps**
- A toleration doesn't attract a Pod to a node, and it doesn't add a taint. Don't taint a node to "test" it here.
- Without `tolerationSeconds`, the Pod would stay on the tainted node forever. With `0`, it's evicted right away.
- Pending **with** a `FailedScheduling` event is a scheduling rule problem. Pending **without** any event is a scheduler problem.

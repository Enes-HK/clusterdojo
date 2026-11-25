**What this tests:** `topologySpreadConstraints` and what happens to them during a rolling update.

```bash
k get node -L topology.kubernetes.io/zone
k -n cdn get pod -o wide                         # all on dojo1-worker
k -n cdn edit deploy edge-cache
```

```yaml
spec:
  replicas: 6
  template:
    spec:
      # nodeSelector: {kubernetes.io/hostname: dojo1-worker}   <- removed
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels: {app: edge-cache}
        matchLabelKeys: [pod-template-hash]
```

```bash
k -n cdn rollout status deploy edge-cache
k -n cdn get pod -o wide                         # 3 on dojo1-worker, 3 on dojo1-worker2
```

**Why `matchLabelKeys: [pod-template-hash]`:** the scheduler counts every Pod that matches `labelSelector`, and that includes the old Pods of the rollout. The new Pods are placed while 4 old Pods still sit in zone-a, so they all go to zone-b to even things out. Once the old ones are gone you can end up with 2 and 4. `matchLabelKeys` adds the Pod's own `pod-template-hash` to the selector, so only Pods of the same revision are counted.

Without it, scaling to 0 and back to 6 also gives an even result:

```bash
k -n cdn scale deploy edge-cache --replicas 0 && k -n cdn scale deploy edge-cache --replicas 6
```

**Traps**
- `whenUnsatisfiable: ScheduleAnyway` only prefers an even spread. "Stays Pending" means `DoNotSchedule`.
- The control plane has no zone label. Nodes without the `topologyKey` label are left out of the count.

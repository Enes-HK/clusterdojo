**What this tests:** reading a rollout's history, the paused state, `rollout undo --to-revision`, and the rolling update knobs.

```bash
k -n shop get deploy,rs,pod
k -n shop rollout history deploy checkout
```

```
REVISION  CHANGE-CAUSE
1         initial release
2         enable cart v2
3         switch payments to stripe
4         nginx patch update
```

```bash
k -n shop rollout history deploy checkout --revision=4      # image nginx:1-alpline: a typo
echo "nginx patch update" > /home/student/answers/m1-14/broken-change
```

A plain `rollout undo` would go back to revision 3, the payment switch. The task wants revision 2. Undo also refuses to run while the Deployment is paused:

```bash
k -n shop rollout undo deploy checkout --to-revision=2
# error: you cannot rollback a paused deployment; resume it first ...
k -n shop rollout resume deploy checkout
k -n shop rollout undo deploy checkout --to-revision=2
```

Then the strategy and the history limit:

```bash
k -n shop patch deploy checkout -p '{"spec":{"revisionHistoryLimit":4,"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
k -n shop rollout status deploy checkout
k -n shop rollout history deploy checkout                    # revision 2 is now 5
```

**Why only one Pod was left:** the old strategy allowed `maxUnavailable: 2` with `maxSurge: 0`. The update removed two working Pods first, and their replacements never started. With `maxUnavailable: 0, maxSurge: 1` the update starts one new Pod and removes an old one only once the new one is ready, so a broken image can't take Pods away.

**Traps**
- `rollout undo` while paused fails. Run `rollout resume` first.
- `rollout undo` without `--to-revision` goes back one revision only.
- A rollback gets a new revision number. The old number disappears from the history, so don't rely on revision numbers after an undo.

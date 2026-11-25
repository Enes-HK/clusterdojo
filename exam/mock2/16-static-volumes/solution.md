**What this tests:** how a PVC finds its PV, and checking the result instead of stopping at "Running". A claim binds only to a PV with the **same** `storageClassName`.

**How to get there:** `k get pv` shows the class of each PV, and `k get sc` shows that `standard` is the default. A PVC without `storageClassName` gets the default class written into it. So:

| The PV has | The PVC needs |
|---|---|
| no class | `storageClassName: ""` |
| class `premium` | `storageClassName: premium` |
| nothing, dynamic provisioning | leave it out, or name the class |

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: records-pv
spec:
  capacity:
    storage: 3Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /mnt/records
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - dojo2-worker
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: records-claim
  namespace: records
spec:
  storageClassName: ""
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
```

Now the Pod starts. But check where the log really goes:

```bash
k -n records get pod -l app=scanner -o wide          # Running on dojo2-worker
ssh dojo2-node1 ls /mnt/records                      # empty!
k -n records get deploy scanner -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'   # mountPath: /dat
k -n records edit deploy scanner                     # mountPath: /data
ssh dojo2-node1 ls /mnt/records                      # scan.log
```

The app wrote into `/data` inside the container's own filesystem, so nothing failed. Only the file on the node shows the mistake.

`storageClassName` can't be changed on an existing PVC, so `buffer-claim` must be recreated:

```bash
k -n records get pvc buffer-claim -o yaml > cache.yaml
vim cache.yaml     # set storageClassName: premium, delete status, uid, resourceVersion, creationTimestamp and the annotations
k -n records delete pvc buffer-claim
k apply -f cache.yaml
k -n records get pvc     # both Bound, VOLUME shows records-pv and premium-pv
```

**Traps**
- The PV's `nodeAffinity` is what puts the Pod on the right node. Without it the Pod can land elsewhere and find no directory.
- `k get pvc` showing `Bound` isn't enough. Check the VOLUME column, because a dynamic volume can bind instead of your PV.
- "Running" isn't "done". Check the result the task asks for, here the file on the node.

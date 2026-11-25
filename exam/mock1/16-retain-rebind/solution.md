**What this tests:** the `Released` phase of a PersistentVolume and how to bind a new claim to a specific volume.

```bash
k get pv
# ledger-pv    1Gi  RWO  Retain  Released   finance/ledger-data  manual
# scratch-pv   1Gi  RWO  Retain  Available                       manual
k -n finance describe pod -l app=ledger           # persistentvolumeclaim "ledger-data" not found
```

A `Released` volume still holds a `claimRef` to the deleted claim (with its old UID), so no new claim can bind to it. Remove that reference. The data on the volume isn't touched:

```bash
k patch pv ledger-pv --type json -p '[{"op":"remove","path":"/spec/claimRef"}]'
k get pv ledger-pv                                # Available
```

Then create the claim and name the volume explicitly:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ledger-data
  namespace: finance
spec:
  storageClassName: manual
  volumeName: ledger-pv
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
```

```bash
k apply -f pvc.yaml
k -n finance get pvc,pod
k -n finance logs deploy/ledger                   # account=operations, balance=4711.20
```

**Traps**
- Without `volumeName`, the claim may bind to the empty `scratch-pv`: same class, same size, already Available.
- Without `storageClassName: manual`, the claim gets the default StorageClass and a new, empty volume.
- `claimRef: null` with a merge patch works too. Editing only the `uid` inside `claimRef` doesn't help, the old claim is gone.

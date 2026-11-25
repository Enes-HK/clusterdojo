**What this tests:** how deletion with finalizers works. A Namespace is only removed after everything in it is gone, and an object with a finalizer waits until something removes that finalizer. Usually that's its controller. Here the controller is gone, so nobody ever will.

**How to get there:** the Namespace's status says what it's waiting for:

```bash
k get ns reports -o yaml | grep -A20 'status:'
#   message: 'Some content in the namespace has finalizers remaining: reports.example.com/archive-before-delete in 1 resource instances'
#   reason: SomeFinalizersRemain
```

Find the object. `k get all` doesn't list custom resources, so ask the API which namespaced types still have objects:

```bash
k api-resources --namespaced -o name | xargs -n1 k -n reports get --ignore-not-found --show-kind
k -n reports get reportjobs -o custom-columns=NAME:.metadata.name,FINALIZERS:.metadata.finalizers
```

Remove the finalizer from that object. Its controller would normally do this after its cleanup work:

```bash
k -n reports patch reportjob quarterly --type=merge -p '{"metadata":{"finalizers":null}}'
k get ns reports                     # NotFound after a few seconds
echo reports.example.com/archive-before-delete > /home/student/answers/m1-09/finalizer
```

**Traps**
- Removing the finalizer from the **Namespace** (`kubernetes` in `spec.finalizers`, via the `finalize` API) also "works", but leaves the objects behind in etcd. Fix the object that blocks it instead.
- Deleting the CRD would delete all its objects too, including ones in other namespaces.
- In real life, first check whether the cleanup the finalizer stands for (here: archiving the report) still has to be done by hand.

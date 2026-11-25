**What this tests:** going from the runtime's view back to Kubernetes. A container ID from a node log means nothing to `kubectl`, but the runtime keeps the Pod's identity in the container's labels.

```bash
sudo -i
cat /var/log/disk-alert.log                       # ... container 3f2a9c1b77e04 writes ...
crictl ps -a | grep 3f2a9c1b77e0                  # crictl also accepts a unique ID prefix:
crictl inspect 3f2a9c1b77e04 | grep -E '"io.kubernetes.(pod.namespace|pod.name|container.name)"'
#  "io.kubernetes.container.name": "uploader",
#  "io.kubernetes.pod.name": "audit-sync",
#  "io.kubernetes.pod.namespace": "ops-tools",
echo ops-tools/audit-sync/uploader > /home/student/answers/m1-05/owner
```

`crictl ps` also has a `POD` column, but it shows the Pod's name only, not its namespace.

The image as the Pod spec names it comes from the Kubernetes side:

```bash
k -n ops-tools get pod audit-sync -o jsonpath='{.spec.containers[?(@.name=="uploader")].image}'   # busybox:1.36
echo busybox:1.36 > /home/student/answers/m1-05/image
```

**Traps**
- The other Pods run look-alike containers called `uploader` too. Only the ID tells them apart.
- `crictl inspect` shows the resolved image (`docker.io/library/busybox:1.36` or a digest). The task asks for the name in the Pod spec.
- `crictl` needs root: `sudo -i` first.

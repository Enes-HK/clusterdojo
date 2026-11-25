**What this tests:** debugging a static Pod when `kubectl` itself is unreliable, and what each probe type does.

- **startupProbe**: "is it up yet?" The other probes wait until it passes once.
- **livenessProbe**: "is it still alive?" On repeated failure the kubelet **kills and restarts** the container.
- **readinessProbe**: "may it get traffic?" On failure it's only removed from Service endpoints, never restarted.

A liveness probe on the wrong port fails even though the app is healthy. The kubelet then kills a perfectly working apiserver every ~1.5 minutes. That's the "works for a few minutes" pattern.

```bash
ssh dojo4
sudo -i
crictl ps -a --name kube-apiserver          # several Exited attempts, ATTEMPT count rising
# kubectl may be down right now; the kubelet's view works anyway:
journalctl -u kubelet --no-pager | grep -i 'probe' | tail -5
#   "Liveness probe failed: ... dial tcp 172.18.0.x:6444: connect: connection refused"
k -n kube-system describe pod kube-apiserver-dojo4-control-plane | grep -A3 -i liveness   # if kubectl works

vim /etc/kubernetes/manifests/kube-apiserver.yaml
#   livenessProbe.httpGet.port: 6444  ->  probe-port   (like readiness/startupProbe)
#   probe-port is a *named* container port, defined under ports: as containerPort 6443 = --secure-port
#   writing 6443 directly works too
# kubelet notices the file change and recreates the Pod by itself, no apply needed
watch crictl ps --name kube-apiserver       # same container ID stays up past 2 minutes
echo spec.containers[].livenessProbe.httpGet.port > /home/student/answers/m1-02/field
```

**The routine for control plane problems:** static Pod manifests in `/etc/kubernetes/manifests` → `crictl ps -a` + `crictl logs <id>` → `journalctl -u kubelet`. These all work even when the apiserver is down.

**Traps**
- Comparing only the main command flags. The probes are further down the same file.
- Keep a backup (`cp kube-apiserver.yaml /root/`) but **not** inside `manifests/`. The kubelet would start every file in that folder as a Pod.
- Changing unrelated things to "make it work" (e.g. deleting the probe entirely). It stops the restarts but isn't the fix.

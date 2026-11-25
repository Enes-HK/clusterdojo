**What this tests:** spotting a missing scheduler, and fixing a control plane static Pod.

A Pod that stays `Pending` usually has a `FailedScheduling` event that says why. Here there's no event at all:

```bash
k -n jobs describe pod -l app=queue-worker          # Events: <none>, Node: <none>
k -n kube-system get pod                            # kube-scheduler-... CrashLoopBackOff (or missing)
```

No event means no scheduler looked at the Pod. Look at the scheduler itself:

```bash
k -n kube-system logs kube-scheduler-dojo4-control-plane
sudo -i
crictl ps -a --name kube-scheduler
crictl logs <container-id>
# ... stat /etc/kubernetes/kube-scheduler.conf: no such file or directory
```

```bash
ls /etc/kubernetes/*.conf                           # admin.conf  controller-manager.conf  kubelet.conf  scheduler.conf ...
vi /etc/kubernetes/manifests/kube-scheduler.yaml
#   - --kubeconfig=/etc/kubernetes/scheduler.conf
```

The kubelet sees the changed manifest and restarts the scheduler within a few seconds. The Pending Pods are then scheduled on their own:

```bash
crictl ps --name kube-scheduler                     # Running
k -n jobs get pod                                   # Running
```

**Traps**
- The other flags (`--authentication-kubeconfig`, `--authorization-kubeconfig`) already point to the right file. Only `--kubeconfig` is wrong.
- Don't delete the Pending Pods or the mirror Pod. That doesn't help, the manifest is the fix.

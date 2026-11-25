**What this tests:** the part kube-proxy plays for Services, and how a DaemonSet decides where its Pods run.

The Service itself looks fine:

```bash
k -n stock get svc,ep,pod -o wide                    # inventory has an endpoint, the Pod is Running
k -n stock run svc-test --rm -it --restart=Never --image=busybox:1 -- wget -qO- -T 3 <pod-ip>:8080   # works
```

So the Pod answers, but the ClusterIP doesn't. ClusterIPs are implemented by kube-proxy on every node (iptables or nftables rules):

```bash
k -n kube-system get ds,pod -l k8s-app=kube-proxy
# daemonset.apps/kube-proxy   0   0   0   0   0   kubernetes.io/os=linux,node-role.kubernetes.io/proxy=   ...
```

DESIRED is 0: the nodeSelector asks for a label that no node has, so every kube-proxy Pod was removed. The rules they had written stay on the nodes, which is why older Services still work. Nobody writes rules for new Services any more.

```bash
k -n kube-system edit ds kube-proxy
```

```yaml
      nodeSelector:
        kubernetes.io/os: linux
        # node-role.kubernetes.io/proxy: ""     <- removed
```

```bash
k -n kube-system get pod -l k8s-app=kube-proxy -o wide      # one per node again
k -n stock run svc-test --rm -it --restart=Never --image=busybox:1 -- wget -qO- -T 3 inventory   # inventory-ok
```

**Traps**
- Labelling the nodes with `node-role.kubernetes.io/proxy` would also bring the Pods back, but it leaves the broken DaemonSet in place. Fix the selector.
- If another task has this cluster's worker down, its kube-proxy Pod can't start until the node is back. The control plane one is enough for the test above.

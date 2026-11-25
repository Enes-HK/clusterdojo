**What this tests:** the CoreDNS config (the Corefile in ConfigMap `coredns`), and adding a second **server block** for one domain. This is the "stub domain" example on the "Customizing DNS Service" page.

```bash
k -n corp-dns get svc corp-resolver            # CLUSTER-IP, e.g. 10.96.123.45
k -n kube-system edit cm coredns
```

Add a new server block **next to** the existing `.:53 { ... }` block, not inside it:

```
.:53 {
    errors
    health
    ...
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
corp.internal:53 {
    errors
    cache 30
    forward . 10.96.123.45
}
```

A server block for `corp.internal` answers every name that ends in `corp.internal`, at any depth. The `reload` plugin in the main block picks the change up by itself, no restart needed. The kubelet first has to sync the ConfigMap into the Pods, so this can take up to about 2 minutes (`k -n kube-system rollout restart deploy coredns` makes it immediate):

```bash
k -n kube-system logs -l k8s-app=kube-dns --tail=5       # "Reloading complete"
k run dns-test --rm -it --restart=Never --image=busybox:1 -- nslookup wiki.corp.internal     # 10.10.10.10
k run dns-test --rm -it --restart=Never --image=busybox:1 -- nslookup kubernetes.default      # still works
```

**Traps**
- A block nested inside `.:53 { }` is a syntax error. CoreDNS then keeps the old config and logs the error, so watch the logs after saving.
- Forward to the ClusterIP, not to `corp-resolver.corp-dns.svc`: CoreDNS can't use a name it would have to resolve itself.
- Keep the old `forward . /etc/resolv.conf` in the main block, or every name outside the cluster stops resolving.

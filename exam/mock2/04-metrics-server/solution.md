**What this tests:** the resource metrics pipeline (metrics-server and its APIService) and reading metrics-server's logs.

```bash
k top nodes                                          # error: Metrics API not available
k get apiservice v1beta1.metrics.k8s.io              # AVAILABLE False (MissingEndpoints)
k -n kube-system get pod -l k8s-app=metrics-server   # Running, but 0/1 ready
k -n kube-system logs deploy/metrics-server
# ... "Failed to scrape node" err="... tls: failed to verify certificate: x509: cannot validate certificate for 172.18.0.x because it doesn't contain any IP SANs"
```

metrics-server reads the metrics from each kubelet over HTTPS. kind's kubelets use self-signed serving certificates, which metrics-server can't verify, so it never becomes ready. The task allows skipping that check:

```bash
k -n kube-system edit deploy metrics-server
```

```yaml
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=10250
        - ...
        - --kubelet-insecure-tls        # added
```

Give it about a minute to collect metrics:

```bash
k -n kube-system rollout status deploy metrics-server
k top nodes
k -n analytics top pod --sort-by=memory              # etl-indexer first
echo etl-indexer > /home/student/answers/m2-04/top-pod
```

**Traps**
- The APIService shows only `MissingEndpoints`. The real reason is in the metrics-server logs.
- `kubectl top` needs a few scrape intervals after the fix. `error: metrics not available yet` means wait, not that the fix is wrong. Right after the fix, `top` can also list only some of the Pods: check that all three are there before you pick one.
- In production you'd sign the kubelet serving certificates (`serverTLSBootstrap: true` and approving their CSRs) instead of skipping verification.

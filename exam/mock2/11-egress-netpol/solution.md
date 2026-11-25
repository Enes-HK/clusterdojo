**What this tests:** egress rules, combining `namespaceSelector` with `podSelector`, and `ipBlock` with `except`.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payments-egress
  namespace: payments
spec:
  podSelector: {}                      # all Pods in payments
  policyTypes: [Egress]                # Ingress not listed: incoming traffic stays as it is
  egress:
  - ports:                             # DNS, to the cluster DNS Pods
    - {protocol: UDP, port: 53}
    - {protocol: TCP, port: 53}
    to:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: kube-system}
      podSelector:
        matchLabels: {k8s-app: kube-dns}
  - ports:                             # app=db Pods in data only
    - {protocol: TCP, port: 5432}
    to:
    - namespaceSelector:
        matchLabels: {kubernetes.io/metadata.name: data}
      podSelector:
        matchLabels: {app: db}
  - ports:
    - {protocol: TCP, port: 443}
    to:
    - ipBlock:
        cidr: 10.20.0.0/16
        except: [10.20.99.0/24]
```

```bash
k apply -f np.yaml
k -n payments exec deploy/api -- wget -qO- -T 3 db.data:5432          # db-ok
k -n payments exec deploy/api -- wget -qO- -T 3 cache.data:6379       # timeout
k -n payments exec deploy/api -- wget -qO- -T 3 db.payments:5432      # timeout
```

**Traps**
- `namespaceSelector` and `podSelector` in **one** list item (no `-` before `podSelector`) means "Pods with app=db in namespace data". As two items they mean "anything in namespace data, or app=db Pods in payments", and `payments/db` would be allowed.
- Listing `Ingress` in `policyTypes` without ingress rules blocks all incoming traffic.
- Without the DNS rule, `db.data` can't even be resolved, so every test fails. Policies apply to the DNS Pods' IPs after the Service IP is translated, so allow the DNS Pods, not the Service's ClusterIP.

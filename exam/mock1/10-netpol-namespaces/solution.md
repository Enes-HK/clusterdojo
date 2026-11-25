**What this tests:** the AND of `namespaceSelector` + `podSelector`, one rule per port, and DNS as its own rule.

**How to get there:** write one rule per numbered line. Line 1 is "these Pods **in** that Namespace", so it's one list item with both selectors. Line 2 is "any Pod", so it's a `namespaceSelector` alone. Line 3 is your own Namespace, so a `podSelector` alone is enough.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: engine-policy
  namespace: treasury
spec:
  podSelector:
    matchLabels:
      app: engine
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: dashboard
      podSelector:              # no dash: same item, so AND
        matchLabels:
          app: console
    ports:
    - protocol: TCP
      port: 9000
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: sre
    ports:
    - protocol: TCP
      port: 9001
  - from:
    - podSelector:
        matchLabels:
          app: reconciler
    ports:
    - protocol: TCP
      port: 9000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: kvstore
    ports:
    - protocol: TCP
      port: 11211
  - ports:                      # dash = new rule, no "to" = any destination
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

```bash
k -n treasury describe netpol engine-policy
CORE=$(k -n treasury get pod -l app=engine -o jsonpath='{.items[0].status.podIP}')
k -n dashboard exec deploy/console -- wget -qO- -T2 $CORE:9000       # engine-app
k -n dashboard-staging exec deploy/console -- wget -qO- -T2 $CORE:9000  # timeout
k -n sre exec deploy/alerts -- wget -qO- -T2 $CORE:9001          # engine-admin
k -n treasury exec deploy/engine -c tools -- nslookup kubernetes.default
```

**Traps**
- The Namespace label is `kubernetes.io/metadata.name`. A label like `namespace: dashboard` doesn't exist, so the selector matches nothing, and kubectl won't warn you.
- A second `- podSelector` with a dash means OR, which also lets in `dashboard-staging/console`.
- Two `ports:` keys in one rule are accepted silently and only the last one is kept. Check with `k describe netpol`.

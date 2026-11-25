**What this tests:** where each Gateway field lives, and how a route attaches across Namespaces.

**How to get there:** `k explain gateway.spec.listeners` and `k explain httproute.spec.rules.backendRefs` show the exact field names. `weight` and `allowedRoutes` are both there, so you don't need to find them in the docs.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: public
  namespace: gateway-infra
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    hostname: "*.example.org"      # quotes: a YAML value can't start with a bare *
    allowedRoutes:
      namespaces:
        from: All
  - name: https
    port: 443
    protocol: HTTPS
    hostname: "*.example.org"
    allowedRoutes:
      namespaces:
        from: All
    tls:
      mode: Terminate
      certificateRefs:
      - name: public-tls
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: news
  namespace: news
spec:
  parentRefs:
  - name: public
    namespace: gateway-infra         # the Gateway is in another Namespace
  hostnames:
  - news.example.org
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /catalog
      headers:                     # no dash: path AND header
      - name: X-Early-Access
        value: "true"
    backendRefs:
    - name: catalog-beta
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /catalog
    backendRefs:
    - name: catalog
      port: 80
  - matches:
    - path:
        type: Exact
        value: /status
    backendRefs:
    - name: status
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: main
      port: 80
      weight: 70
    - name: preview
      port: 80
      weight: 30
```

```bash
k -n news describe httproute news     # Accepted: True, ResolvedRefs: True
IP=$(k -n gateway-infra get svc public-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: news.example.org' -H 'X-Early-Access: true' http://$IP/catalog    # catalog-beta
for i in $(seq 20); do curl -s -H 'Host: news.example.org' http://$IP/; done | sort | uniq -c
```

**Traps**
- `parentRefs` without `namespace` looks in the route's own Namespace, so the route never attaches.
- `tls` sits on the listener, and the Secret goes under `certificateRefs`.
- `"true"` needs quotes, because the header value must be a string.
- Check `describe httproute` first. If `Accepted` is False, no curl will work, and the message says why.

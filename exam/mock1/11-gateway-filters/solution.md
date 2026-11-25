**What this tests:** HTTPRoute `filters`: they change a request on its way (rewrite, headers) or answer it directly (redirect). They're listed per rule, and a redirect rule has no `backendRefs`.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: portal
  namespace: portal
spec:
  parentRefs:
  - name: portal-gw
  hostnames:
  - portal.local
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /old-api
    filters:
    - type: URLRewrite
      urlRewrite:
        path:
          type: ReplacePrefixMatch
          replacePrefixMatch: /api
    backendRefs:
    - name: api
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /api
    filters:
    - type: RequestHeaderModifier
      requestHeaderModifier:
        add:
        - name: X-Env
          value: prod
    backendRefs:
    - name: api
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /login
    filters:
    - type: RequestRedirect
      requestRedirect:
        scheme: https
        statusCode: 301
  - backendRefs:              # no matches = path prefix "/" = everything else
    - name: web
      port: 80
```

```bash
IP=$(k -n portal get svc portal-gw-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: portal.local' http://$IP/old-api/users        # api path=/api/users x-env=
curl -s -H 'Host: portal.local' http://$IP/api/orders           # api path=/api/orders x-env=prod
curl -si -H 'Host: portal.local' http://$IP/login | head -3     # 301, Location: https://portal.local/login
k -n portal describe httproute portal | grep -A3 Conditions     # Accepted, ResolvedRefs
```

**Traps**
- `ReplaceFullPath` would turn `/old-api/users` into `/api` for every request. `ReplacePrefixMatch` keeps the rest of the path.
- The redirect keeps host and path by default, so `scheme: https` is all it needs. Don't add a `backendRefs` to that rule.
- The rule order in the YAML doesn't matter. The longest matching prefix wins, so `/old-api` and `/api` never clash with the catch-all.

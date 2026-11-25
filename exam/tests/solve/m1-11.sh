source /root/exam/bin/lib.sh
kc dojo1 apply -f - <<'Y'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: portal, namespace: portal}
spec:
  parentRefs: [{name: portal-gw}]
  hostnames: [portal.local]
  rules:
  - matches: [{path: {type: PathPrefix, value: /old-api}}]
    filters: [{type: URLRewrite, urlRewrite: {path: {type: ReplacePrefixMatch, replacePrefixMatch: /api}}}]
    backendRefs: [{name: api, port: 80}]
  - matches: [{path: {type: PathPrefix, value: /api}}]
    filters: [{type: RequestHeaderModifier, requestHeaderModifier: {add: [{name: X-Env, value: prod}]}}]
    backendRefs: [{name: api, port: 80}]
  - matches: [{path: {type: PathPrefix, value: /login}}]
    filters: [{type: RequestRedirect, requestRedirect: {scheme: https, statusCode: 301}}]
  - backendRefs: [{name: web, port: 80}]
Y
sleep 8

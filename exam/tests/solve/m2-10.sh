source /root/exam/bin/lib.sh
kc dojo1 apply -f - <<'Y'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: public, namespace: gateway-infra}
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    hostname: "*.example.org"
    allowedRoutes: {namespaces: {from: All}}
  - name: https
    port: 443
    protocol: HTTPS
    hostname: "*.example.org"
    allowedRoutes: {namespaces: {from: All}}
    tls:
      mode: Terminate
      certificateRefs: [{name: public-tls}]
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: news, namespace: news}
spec:
  parentRefs: [{name: public, namespace: gateway-infra}]
  hostnames: [news.example.org]
  rules:
  - matches:
    - path: {type: PathPrefix, value: /catalog}
      headers: [{name: X-Early-Access, value: "true"}]
    backendRefs: [{name: catalog-beta, port: 80}]
  - matches: [{path: {type: PathPrefix, value: /catalog}}]
    backendRefs: [{name: catalog, port: 80}]
  - matches: [{path: {type: Exact, value: /status}}]
    backendRefs: [{name: status, port: 80}]
  - matches: [{path: {type: PathPrefix, value: /}}]
    backendRefs:
    - {name: main, port: 80, weight: 70}
    - {name: preview, port: 80, weight: 30}
Y
wait_for 120 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n gateway-infra get svc public-nginx"
kc dojo1 -n gateway-infra rollout status deploy/public-nginx --timeout=120s
sleep 5

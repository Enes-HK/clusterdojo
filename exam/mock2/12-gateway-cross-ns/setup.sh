source /root/exam/bin/lib.sh
drop_ns dojo1 edge storefront backends
kc dojo1 create ns edge
kc dojo1 create ns storefront
kc dojo1 create ns backends
kc dojo1 -n backends create deploy catalog-api --image=hashicorp/http-echo:1.0 -- /http-echo -text=catalog-api-ok -listen=:5678
kc dojo1 -n backends expose deploy catalog-api --port=80 --target-port=5678
kc dojo1 -n backends create deploy billing-api --image=hashicorp/http-echo:1.0 -- /http-echo -text=billing-api-ok -listen=:5678
kc dojo1 -n backends expose deploy billing-api --port=80 --target-port=5678
kc dojo1 apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: shared-gw, namespace: edge}
spec:
  gatewayClassName: nginx
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    hostname: store.local
    allowedRoutes:
      namespaces:
        from: Selector
        selector:
          matchLabels: {gateway-access: granted}
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata: {name: store, namespace: storefront}
spec:
  parentRefs: [{name: shared-gw, namespace: edge}]
  hostnames: [store.local]
  rules:
  - backendRefs: [{name: catalog-api, namespace: backends, port: 80}]
---
# the namespace is misspelled, so it grants nothing to storefront
apiVersion: gateway.networking.k8s.io/v1beta1
kind: ReferenceGrant
metadata: {name: storefront-to-catalog, namespace: backends}
spec:
  from:
  - {group: gateway.networking.k8s.io, kind: HTTPRoute, namespace: store-front}
  to:
  - {group: "", kind: Service, name: catalog-api}
EOF
kc dojo1 -n backends rollout status deploy/catalog-api --timeout=90s
kc dojo1 -n backends rollout status deploy/billing-api --timeout=90s
wait_for 120 kc dojo1 -n edge get svc shared-gw-nginx

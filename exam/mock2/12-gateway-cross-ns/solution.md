**What this tests:** the two checks Gateway API makes across Namespaces: the Gateway's `allowedRoutes`, and `ReferenceGrant` for backends in another Namespace. Both show up in the route's status.

```bash
k -n storefront describe httproute store
# Parents:  shared-gw
#   Accepted  False  NotAllowedByListeners
```

The listener only takes routes from Namespaces with `gateway-access=granted`, and `storefront` doesn't have it:

```bash
k get ns storefront --show-labels
k label ns storefront gateway-access=granted
k -n storefront describe httproute store
#   Accepted      True
#   ResolvedRefs  False  RefNotPermitted
```

Now the route is attached, but it may not point to a Service in another Namespace unless that Namespace allows it with a ReferenceGrant. There is one, but for the wrong Namespace:

```bash
k -n backends get referencegrant storefront-to-catalog -o yaml     # from.namespace: store-front
k -n backends edit referencegrant storefront-to-catalog
```

```yaml
spec:
  from:
  - group: gateway.networking.k8s.io
    kind: HTTPRoute
    namespace: storefront
  to:
  - group: ""
    kind: Service
    name: catalog-api
```

```bash
k -n storefront describe httproute store                 # ResolvedRefs True
IP=$(k -n edge get svc shared-gw-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: store.local' http://$IP/              # catalog-api-ok
```

**Traps**
- A ReferenceGrant lives in the Namespace of the **target** (`backends`), not of the route.
- Without `name` under `to`, the grant would cover every Service in `backends`, including `billing-api`.
- Changing the Gateway to `from: All` would also "work", but it opens the Gateway to every Namespace.

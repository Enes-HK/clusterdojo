---
title: A route across three Namespaces
host: dojo1
docs: https://gateway-api.sigs.k8s.io/guides/multiple-ns/ | Cross-Namespace routing ; https://gateway-api.sigs.k8s.io/api-types/referencegrant/ | ReferenceGrant ; https://kubernetes.io/docs/concepts/services-networking/gateway/ | Gateway API
---
> Target: 6 minutes

Three teams share one Gateway:

- Gateway `shared-gw` lives in Namespace `edge` and only accepts routes from Namespaces labelled `gateway-access=granted`.
- HTTPRoute `store` in Namespace `storefront` sends `store.local` to Service `catalog-api` in Namespace `backends`.

Requests to `http://store.local/` through the Gateway don't reach `catalog-api`. Find out why and fix it.

- Don't change Gateway `shared-gw` or HTTPRoute `store`.
- Whatever you allow in `backends` must allow only HTTPRoutes from `storefront`, and only to Service `catalog-api`.

The Gateway gets a Service named `shared-gw-nginx` in Namespace `edge`. You can test from `dojo1` with:

```
IP=$(k -n edge get svc shared-gw-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: store.local' http://$IP/
```

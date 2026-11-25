---
title: Gateway API redirects, rewrites and headers
host: dojo1
docs: https://kubernetes.io/docs/concepts/services-networking/gateway/ | Gateway API ; https://gateway-api.sigs.k8s.io/guides/http-redirect-rewrite/ | HTTP redirects and rewrites ; https://gateway-api.sigs.k8s.io/guides/http-header-modifier/ | HTTP header modifiers
---
> Target: 9 minutes

In Namespace `portal` there's a Gateway named `portal-gw` and the Services `web` and `api` (both port `80`).

Create an HTTPRoute named `portal` in Namespace `portal`, attached to Gateway `portal-gw`, for the hostname `portal.local`, with these rules:

1. Requests to `/old-api` (and below) go to Service `api`, with the prefix `/old-api` replaced by `/api`. For example, `/old-api/users` arrives at `api` as `/api/users`
2. Requests to `/api` (and below) go to Service `api`, with the request header `X-Env: prod` added
3. Requests to `/login` get a redirect to `https://portal.local/login` with status code `301`
4. Every other request goes to Service `web`

The `api` Service answers with the path and the `X-Env` header it received. You can test from `dojo1`:

```
IP=$(k -n portal get svc portal-gw-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: portal.local' http://$IP/old-api/users
curl -si -H 'Host: portal.local' http://$IP/login | head -3
```

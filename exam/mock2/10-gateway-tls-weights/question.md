---
title: Gateway with TLS and weighted routes
host: dojo1
docs: https://kubernetes.io/docs/concepts/services-networking/gateway/ | Gateway API ; https://gateway-api.sigs.k8s.io/guides/tls/ | TLS ; https://gateway-api.sigs.k8s.io/guides/traffic-splitting/ | Traffic splitting ; https://gateway-api.sigs.k8s.io/guides/multiple-ns/ | Cross-Namespace routing
---
> Target: 12 minutes

Namespace `gateway-infra` contains the TLS Secret `public-tls`. Namespace `news` contains the Services `main`, `preview`, `catalog`, `catalog-beta` and `status`, all on port `80`.

1. Create a Gateway named `public` in Namespace `gateway-infra` using GatewayClass `nginx`, with these two listeners. Both use hostname `*.example.org` and must accept routes from **all** Namespaces:
    - `http` on port `80`, protocol `HTTP`
    - `https` on port `443`, protocol `HTTPS`, terminating TLS with Secret `public-tls`

2. Create an HTTPRoute named `news` in Namespace `news`, attached to Gateway `public`, for hostname `news.example.org`, with these rules:
    - Requests to `/catalog` (and below) **with** header `X-Early-Access: true` go to Service `catalog-beta`
    - All other requests to `/catalog` (and below) go to Service `catalog`
    - Requests to **exactly** `/status` go to Service `status`
    - Every other request is split: `70%` to Service `main`, `30%` to Service `preview`

The Gateway gets a Service named `public-nginx` in Namespace `gateway-infra`. You can test from `dojo1` with:

```
IP=$(k -n gateway-infra get svc public-nginx -o jsonpath='{.spec.clusterIP}')
curl -s -H 'Host: news.example.org' http://$IP/catalog
curl -sk --resolve news.example.org:443:$IP https://news.example.org/status
```

---
title: Lock down outgoing traffic
host: dojo2
docs: https://kubernetes.io/docs/concepts/services-networking/network-policies/ | Network Policies ; https://kubernetes.io/docs/reference/kubernetes-api/networking-resources/network-policy-v1/ | NetworkPolicy API
---
> Target: 7 minutes

Pods in Namespace `payments` may currently connect anywhere. Create one NetworkPolicy named `payments-egress` in `payments` so that **all** its Pods may only open these connections:

- DNS lookups to the cluster DNS, UDP and TCP port 53
- Pods with label `app=db` in Namespace `data`, TCP port 5432
- the partner network `10.20.0.0/16` on TCP port 443, except the subnet `10.20.99.0/24`

Every other outgoing connection must be blocked. Incoming traffic to `payments` must stay as it is.

You can test from Deployment `api`:

```
k -n payments exec deploy/api -- wget -qO- -T 3 db.data:5432
```

---
title: Three Service repairs
host: dojo2
docs: https://kubernetes.io/docs/concepts/services-networking/service/ | Service ; https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/ | Probes ; https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/ | EndpointSlices
---
> Target: 9 minutes

All of this happens in Namespace `support`. Pod `toolbox` is there for testing, for example:

```
k -n support exec toolbox -- wget -qO- -T3 helpdesk
```

1. Service `helpdesk` has no endpoints, although the `helpdesk` Pods are running. Fix this by changing **only** the Service
2. Service `reporter` has no **ready** endpoints, although the Pod of Deployment `reporter` is running. Fix this by changing **only** the Deployment `reporter`, and keep its readiness probe
3. A database server in another Namespace answers on port `9500` at the IP of Pod `remote-db` in Namespace `external` (treat that IP as a fixed server address). Create a Service named `warehouse-db` **without a selector**, on port `3306`, and an EndpointSlice named `warehouse-db-1` that sends its traffic to that IP and port.

`k -n support exec toolbox -- wget -qO- -T3 warehouse-db:3306` must print `warehouse-db-ok`.

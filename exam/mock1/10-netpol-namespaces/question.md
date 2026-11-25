---
title: NetworkPolicy across Namespaces
host: dojo1
docs: https://kubernetes.io/docs/concepts/services-networking/network-policies/ | Network Policies
---
> Target: 9 minutes, including testing

Namespace `treasury` runs the Deployments `engine` (label `app=engine`, ports `9000` app and `9001` admin), `kvstore` (label `app=kvstore`, ports `11211` and `11212`) and `reconciler` (label `app=reconciler`). Currently everything can talk to everything.

Create a NetworkPolicy named `engine-policy` in Namespace `treasury` that applies to the `engine` Pods and allows **only** the following:

**Incoming**
1. From Pods with label `app=console` in Namespace `dashboard`, on port `9000` only
2. From **any** Pod in Namespace `sre`, on port `9001` only
3. From Pods with label `app=reconciler` in Namespace `treasury`, on port `9000` only

**Outgoing**
4. To Pods with label `app=kvstore` in Namespace `treasury`, on port `11211` only
5. DNS lookups (port `53`, TCP and UDP) must still work

Note that Namespace `dashboard-staging` also has a Pod with label `app=console`. It must **not** get access.

Traffic between other Pods must not be affected.

You can test with, for example:

```
API=$(k -n treasury get pod -l app=engine -o jsonpath='{.items[0].status.podIP}')
k -n dashboard exec deploy/console -- wget -qO- -T2 $API:9000
```

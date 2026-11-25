---
title: Forward a private DNS domain
host: dojo2
docs: https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/ | Customizing DNS Service ; https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/ | Debugging DNS Resolution
---
> Target: 7 minutes

The company runs its own DNS server for the private domain `corp.internal`. In this cluster it's reachable through Service `corp-resolver` in Namespace `corp-dns`.

Configure the cluster DNS so that Pods resolve **every** name under `corp.internal` through that server, using the Service's ClusterIP. All other lookups must keep working as before.

You can test with:

```
k run dns-test --rm -it --restart=Never --image=busybox:1 -- nslookup wiki.corp.internal
```

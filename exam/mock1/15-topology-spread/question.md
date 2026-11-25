---
title: Spread a Deployment over zones
host: dojo1
docs: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/ | Pod Topology Spread Constraints ; https://kubernetes.io/docs/reference/labels-annotations-taints/ | Well-Known Labels, Annotations and Taints
---
> Target: 6 minutes

Deployment `edge-cache` in Namespace `cdn` runs all its Pods on a single node. The worker nodes of this cluster sit in two zones, shown by their label `topology.kubernetes.io/zone`.

Change `edge-cache` so that:

- it's no longer tied to one node,
- it runs **6** replicas,
- the number of its Pods per zone differs by at most one,
- a Pod that can't be placed without breaking that rule stays Pending instead of being placed unevenly.

At the end all 6 Pods must be running, 3 in each zone.

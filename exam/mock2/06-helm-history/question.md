---
title: Helm values, rollback and versions
host: dojo2
docs: https://helm.sh/docs/helm/helm_upgrade/ | helm upgrade ; https://helm.sh/docs/helm/helm_rollback/ | helm rollback ; https://helm.sh/docs/helm/helm_get_values/ | helm get values ; https://helm.sh/docs/helm/helm_search_repo/ | helm search repo
---
> Target: 7 minutes

The Helm repository `acme` is already configured for user `student` on `dojo2`. Chart `acme/webapp` has the value `replicaCount`.

1. Write the user-supplied values of release `jukebox` in Namespace `streaming` to `/home/student/answers/m2-06/jukebox-values.yaml`
2. Upgrade release `jukebox` to chart version `1.2.0` and run it with `3` replicas. The values it already has must stay as they are
3. Release `broadcast` in Namespace `streaming` stopped working after its latest upgrade. Roll it back to the last revision that worked
4. Install a new release `audiobook` into the new Namespace `streaming-labs` using chart version **exactly** `1.0.0`, with `service.type=NodePort`

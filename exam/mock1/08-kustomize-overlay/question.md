---
title: Kustomize overlay with generated config
host: dojo2
docs: https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/ | Declarative Management with Kustomize
---
> Target: 8 minutes

The app `notes` is managed with Kustomize in `/home/student/notes-app` on `dojo2`: a `base` and an overlay `overlays/prod`, which deploys into Namespace `notes-prod`. Change only files in `overlays/prod`, never the base.

1. Prod must run the image `nginx:1.29-alpine` for the container of Deployment `notes`. Use the overlay's `images` field
2. Generate a ConfigMap named `notes-config` from the file `overlays/prod/settings.env` (each line becomes one key) and load **all** its keys as environment variables into the container of Deployment `notes`
3. Apply the overlay. Then set `LOG_LEVEL=debug` in `settings.env` and apply again. The running Pods must get the new value without any manual restart

Apply with `kubectl apply -k /home/student/notes-app/overlays/prod`.

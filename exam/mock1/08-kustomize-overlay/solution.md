**What this tests:** the two Kustomize features that save the most work: `images` (no patch needed for a tag) and `configMapGenerator` (a hash in the name, so a config change rolls the Pods).

```bash
cd /home/student/notes-app
cat base/deployment.yaml overlays/prod/kustomization.yaml       # container name: web
```

`overlays/prod/kustomization.yaml`:

```yaml
namespace: notes-prod
resources:
- namespace.yaml
- ../../base
patches:
- path: replicas.yaml
- path: env.yaml
images:
- name: nginx                # the image name as the base uses it, without the tag
  newTag: 1.29-alpine
configMapGenerator:
- name: notes-config
  envs:
  - settings.env             # envs: every line becomes its own key (files: would make one key with the whole file)
```

`overlays/prod/env.yaml`, a patch that adds `envFrom`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes
spec:
  template:
    spec:
      containers:
      - name: web
        envFrom:
        - configMapRef:
            name: notes-config     # Kustomize rewrites this to notes-config-<hash>
```

```bash
k kustomize overlays/prod | grep -E 'image:|notes-config'      # check before applying
k apply -k overlays/prod
sed -i 's/^LOG_LEVEL=.*/LOG_LEVEL=debug/' overlays/prod/settings.env
k apply -k overlays/prod                                        # new hash -> new Pod template -> rollout
k -n notes-prod rollout status deploy notes
k -n notes-prod exec deploy/notes -- env | grep LOG_LEVEL       # debug
```

**Why no restart is needed:** the ConfigMap's name contains a hash of its content. A new value means a new name, the Deployment's Pod template changes, and that starts a rollout. With a plain ConfigMap, the Pods would keep the old environment until someone restarts them.

**Traps**
- `files:` instead of `envs:` creates one key `settings.env` holding the whole file.
- Writing `name: notes-config-abc123` in the patch: always use the generator's name, Kustomize adds the hash.
- Editing the base also changes every other overlay. The task says prod only.

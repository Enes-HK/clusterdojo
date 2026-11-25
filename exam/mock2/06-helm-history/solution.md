**What this tests:** keeping values on upgrade, reading release history, and pinning a version.

```bash
helm get values jukebox -n streaming                                   # what was set by hand
helm get values jukebox -n streaming > /home/student/answers/m2-06/jukebox-values.yaml

helm search repo acme/webapp --versions
helm upgrade jukebox acme/webapp -n streaming --version 1.2.0 --reuse-values --set replicaCount=3
helm get values jukebox -n streaming                                   # banner and port still there
```

Without `--reuse-values`, an upgrade goes back to chart defaults plus only what you set in that command. So `banner` and `service.port` would be lost.

```bash
helm history broadcast -n streaming            # revision 1 worked, revision 2 is the bad image
k -n streaming get pods                    # ImagePullBackOff
helm rollback broadcast 1 -n streaming
k -n streaming rollout status deploy/broadcast
```

```bash
helm install audiobook acme/webapp -n streaming-labs --create-namespace --version 1.0.0 --set service.type=NodePort
helm list -A
```

**Traps**
- `helm history` is what tells you which revision to return to. Don't guess.
- A failed image doesn't make the release `failed` unless the upgrade used `--wait`. It can show `deployed` and still be broken, so check the Pods.
- Without `--version`, `helm install` takes the latest chart.
- `--create-namespace` is needed for a new Namespace.

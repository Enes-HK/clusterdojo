**What this tests:** sharing files between containers, native sidecars, and mounting one file with `subPath`.

**Native sidecar** = an entry in `initContainers` with `restartPolicy: Always`. Normal init containers must *finish* before the app starts. With `restartPolicy: Always`, the kubelet starts it, doesn't wait for it to exit, keeps it running next to the app, and restarts it if it dies. A plain second entry in `containers:` also runs alongside, but has no "starts before app" guarantee. Use the native form when the task says *native* / *before* / *initContainers*.

**Mounting a volume at a directory hides everything that was in that directory.** Mount a ConfigMap at `/etc` and `/etc/passwd` is gone. `subPath: app.conf` mounts just that one key as one file.

```bash
ssh dojo1
k -n logging edit deploy ingest
```
```yaml
    spec:
      initContainers:
      - name: shipper
        image: busybox:1
        restartPolicy: Always                 # <- this makes it a sidecar
        command: [sh, -c, 'tail -F /var/log/app/app.log']
        volumeMounts:
        - {name: logs, mountPath: /var/log/app}
      containers:
      - name: app
        ...
        volumeMounts:
        - {name: logs, mountPath: /var/log/app}
        - {name: config, mountPath: /etc/app.conf, subPath: app.conf}
      volumes:
      - name: logs
        emptyDir: {}
      - name: config
        configMap: {name: ingest-config}
```
```bash
k -n logging logs deploy/ingest -c shipper -f     # lines appear every 5s
k -n logging exec deploy/ingest -c app -- cat /etc/app.conf
k -n logging exec deploy/ingest -c app -- ls /etc | head
```

**Traps**
- `tail -f` vs `tail -F`: `-F` keeps retrying if the file doesn't exist yet. The sidecar starts *before* the app, so at first there's no file.
- Each container needs its own `volumeMounts`. Declaring the volume once under `volumes:` doesn't mount it anywhere.
- Files mounted with `subPath` do **not** receive ConfigMap updates. A directory mount does.

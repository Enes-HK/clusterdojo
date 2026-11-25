**What this tests:** several small things you've mixed up before, in one spec.

**How to get there:** start from `k -n payroll create deploy payslip --image=busybox:1 --dry-run=client -o yaml > d.yaml`, then add one numbered line at a time. Use `k explain deploy.spec.template.spec.containers.readinessProbe.exec` for field names.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payslip
  namespace: payroll
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payslip
  template:
    metadata:
      labels:
        app: payslip
    spec:
      volumes:
      - name: shared
        emptyDir: {}
      - name: config
        configMap:
          name: payslip-config
      initContainers:
      - name: prepare
        image: busybox:1
        command: ["sh", "-c", "echo ready > /shared/state.txt"]
        volumeMounts:
        - name: shared
          mountPath: /shared
      containers:
      - name: app
        image: busybox:1
        command: ["sh", "-c", "while true; do date >> /shared/app.log; sleep 3; done"]
        env:
        - name: PG_USER            # the variable
          valueFrom:
            secretKeyRef:
              name: pg-credentials       # the Secret
              key: username        # the key inside it
        - name: PG_PASSWORD
          valueFrom:
            secretKeyRef:
              name: pg-credentials
              key: password
        readinessProbe:
          periodSeconds: 10
          exec:
            command: ["sh", "-c", "grep -q ready /shared/state.txt && test -s /shared/app.log"]
        volumeMounts:
        - name: shared
          mountPath: /shared
        - name: config
          mountPath: /etc/payroll.ini   # where it appears
          subPath: payroll.ini          # the key name
      - name: log-forwarder
        image: busybox:1
        command: ["sh", "-c", "tail -F /shared/app.log"]
        volumeMounts:
        - name: shared
          mountPath: /shared
```

```bash
k -n payroll get pod
k -n payroll exec deploy/payslip -c app -- sh -c 'echo $PG_USER; cat /etc/payroll.ini; ls /etc | wc -l'
k -n payroll logs deploy/payslip -c log-forwarder --tail=3
```

**Traps**
- `&&` and `>` only work in a shell. `exec` doesn't start one, so the command needs `["sh", "-c", "..."]`.
- busybox has `sh`, not `bash`.
- Without `subPath`, the mount replaces everything in the target directory.
- `env.name` is the variable, `secretKeyRef.name` is the Secret. They are easy to swap.
- A plain sidecar is a second entry in `containers:`. Use a native sidecar (`initContainers` with `restartPolicy: Always`) only when the task asks.

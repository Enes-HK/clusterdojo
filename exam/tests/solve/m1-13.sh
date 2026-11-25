source /root/exam/bin/lib.sh
kc dojo2 apply -f - <<'Y'
apiVersion: apps/v1
kind: Deployment
metadata: {name: payslip, namespace: payroll}
spec:
  replicas: 1
  selector: {matchLabels: {app: payslip}}
  template:
    metadata: {labels: {app: payslip}}
    spec:
      volumes:
      - {name: shared, emptyDir: {}}
      - {name: config, configMap: {name: payslip-config}}
      initContainers:
      - name: prepare
        image: busybox:1
        command: [sh, -c, 'echo ready > /shared/state.txt']
        volumeMounts: [{name: shared, mountPath: /shared}]
      containers:
      - name: app
        image: busybox:1
        command: [sh, -c, 'while true; do date >> /shared/app.log; sleep 3; done']
        env:
        - name: PG_USER
          valueFrom: {secretKeyRef: {name: pg-credentials, key: username}}
        - name: PG_PASSWORD
          valueFrom: {secretKeyRef: {name: pg-credentials, key: password}}
        readinessProbe:
          periodSeconds: 10
          exec: {command: [sh, -c, 'grep -q ready /shared/state.txt && test -s /shared/app.log']}
        volumeMounts:
        - {name: shared, mountPath: /shared}
        - {name: config, mountPath: /etc/payroll.ini, subPath: payroll.ini}
      - name: log-forwarder
        image: busybox:1
        command: [sh, -c, 'tail -F /shared/app.log']
        volumeMounts: [{name: shared, mountPath: /shared}]
Y
kc dojo2 -n payroll rollout status deploy/payslip --timeout=90s

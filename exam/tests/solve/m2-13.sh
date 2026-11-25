source /root/exam/bin/lib.sh
kc dojo1 -n logging patch deploy ingest --type=strategic -p '
spec:
  template:
    spec:
      initContainers:
      - name: shipper
        image: busybox:1
        restartPolicy: Always
        command: [sh, -c, "tail -F /var/log/app/app.log"]
        volumeMounts: [{name: logs, mountPath: /var/log/app}]
      containers:
      - name: app
        volumeMounts:
        - {name: logs, mountPath: /var/log/app}
        - {name: config, mountPath: /etc/app.conf, subPath: app.conf}
      volumes:
      - {name: logs, emptyDir: {}}
      - {name: config, configMap: {name: ingest-config}}'
kc dojo1 -n logging rollout status deploy/ingest --timeout=120s
sleep 8

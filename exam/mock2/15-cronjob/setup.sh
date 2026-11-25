source /root/exam/bin/lib.sh
answers dojo1 m2-15
drop_ns dojo1 reports
kc dojo1 create ns reports
kc dojo1 apply -f - <<'EOF'
apiVersion: batch/v1
kind: CronJob
metadata: {name: nightly-export, namespace: reports}
spec:
  schedule: "30 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: export
            image: busybox:1
            command: [sh, -c, 'echo "export started"; sleep 10; echo "export finished: 1284 rows written to /exports/nightly.csv"']
EOF

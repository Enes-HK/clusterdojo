source /root/exam/bin/lib.sh
answers dojo3 m1-09
# a leftover from an earlier run: let it finish first
if kc dojo3 get ns reports >/dev/null 2>&1; then
  for r in $(kc dojo3 -n reports get reportjobs.reports.example.com -o name 2>/dev/null); do
    kc dojo3 -n reports patch "$r" --type=merge -p '{"metadata":{"finalizers":null}}'
  done
  kc dojo3 delete ns reports --ignore-not-found --wait --timeout=60s
fi
kc dojo3 apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata: {name: reportjobs.reports.example.com}
spec:
  group: reports.example.com
  scope: Namespaced
  names: {plural: reportjobs, singular: reportjob, kind: ReportJob, shortNames: [rj]}
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              schedule: {type: string}
              format: {type: string}
EOF
kc dojo3 wait crd reportjobs.reports.example.com --for=condition=Established --timeout=60s
kc dojo3 create ns reports
kc dojo3 -n reports create configmap report-templates --from-literal=header="Quarterly report"
kc dojo3 apply -f - <<'EOF'
apiVersion: reports.example.com/v1
kind: ReportJob
metadata:
  name: quarterly
  namespace: reports
  finalizers: [reports.example.com/archive-before-delete]
spec: {schedule: "0 6 1 */3 *", format: pdf}
---
apiVersion: reports.example.com/v1
kind: ReportJob
metadata:
  name: weekly
  namespace: reports
spec: {schedule: "0 6 * * 1", format: csv}
EOF
kc dojo3 delete ns reports --wait=false
sleep 5
kc dojo3 get ns reports

source /root/exam/bin/lib.sh
kc dojo2 -n support patch svc helpdesk --type=json -p '[{"op":"remove","path":"/spec/selector/tier"}]'
kc dojo2 -n support patch deploy reporter --type=json -p '[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":8080}]'
kc dojo2 -n support rollout status deploy/reporter --timeout=90s
ip=$(kc dojo2 -n external get pod remote-db -o jsonpath='{.status.podIP}')
kc dojo2 apply -f - <<Y
apiVersion: v1
kind: Service
metadata: {name: warehouse-db, namespace: support}
spec:
  ports: [{name: db, port: 3306, targetPort: 9500}]
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: warehouse-db-1
  namespace: support
  labels: {kubernetes.io/service-name: warehouse-db}
addressType: IPv4
ports: [{name: db, port: 9500, protocol: TCP}]
endpoints: [{addresses: ["$ip"]}]
Y
sleep 5

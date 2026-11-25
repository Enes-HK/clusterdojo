source /root/exam/bin/lib.sh
drop_ns dojo1 portal
kc dojo1 create ns portal
kc dojo1 apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata: {name: portal-gw, namespace: portal}
spec:
  gatewayClassName: nginx
  listeners:
  - {name: http, port: 80, protocol: HTTP, hostname: portal.local}
---
# api answers with the path and the X-Env header it got, so rewrites and added headers are visible
apiVersion: v1
kind: ConfigMap
metadata: {name: api-conf, namespace: portal}
data:
  default.conf: |
    server {
      listen 8080;
      location / {
        default_type text/plain;
        return 200 "api path=$request_uri x-env=$http_x_env\n";
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata: {name: api, namespace: portal}
spec:
  selector: {matchLabels: {app: api}}
  template:
    metadata: {labels: {app: api}}
    spec:
      containers:
      - name: api
        image: nginx:1-alpine
        volumeMounts: [{name: conf, mountPath: /etc/nginx/conf.d}]
      volumes: [{name: conf, configMap: {name: api-conf}}]
---
apiVersion: v1
kind: Service
metadata: {name: api, namespace: portal}
spec:
  selector: {app: api}
  ports: [{port: 80, targetPort: 8080}]
EOF
kc dojo1 -n portal create deploy web --image=hashicorp/http-echo:1.0 -- /http-echo -text=web -listen=:5678
kc dojo1 -n portal expose deploy web --port=80 --target-port=5678
kc dojo1 -n portal rollout status deploy/api --timeout=120s
kc dojo1 -n portal rollout status deploy/web --timeout=120s
wait_for 120 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n portal get svc portal-gw-nginx"
kc dojo1 -n portal rollout status deploy/portal-gw-nginx --timeout=180s

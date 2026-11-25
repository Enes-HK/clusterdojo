source /root/exam/bin/lib.sh
on dojo2 'export KUBECONFIG=/etc/kubernetes/admin.conf; d=/home/student/notes-app/overlays/prod; cd $d
cat >> kustomization.yaml <<EOF
- path: env.yaml
images:
- name: nginx
  newTag: 1.29-alpine
configMapGenerator:
- name: notes-config
  envs:
  - settings.env
EOF
cat > env.yaml <<EOF
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
            name: notes-config
EOF
kubectl apply -k . && kubectl -n notes-prod rollout status deploy/notes --timeout=120s
sed -i "s/^LOG_LEVEL=.*/LOG_LEVEL=debug/" settings.env
kubectl apply -k . && kubectl -n notes-prod rollout status deploy/notes --timeout=120s
chown -R student:student /home/student/notes-app'

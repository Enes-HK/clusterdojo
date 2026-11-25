source /root/exam/bin/lib.sh
drop_ns dojo2 notes-prod
on dojo2 'd=/home/student/notes-app; rm -rf $d; mkdir -p $d/base $d/overlays/prod
cat > $d/base/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes
spec:
  replicas: 1
  selector:
    matchLabels:
      app: notes
  template:
    metadata:
      labels:
        app: notes
    spec:
      containers:
      - name: web
        image: nginx:1-alpine
        ports:
        - containerPort: 80
EOF
cat > $d/base/service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: notes
spec:
  selector:
    app: notes
  ports:
  - port: 80
EOF
cat > $d/base/kustomization.yaml <<EOF
resources:
- deployment.yaml
- service.yaml
EOF
cat > $d/overlays/prod/namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: notes-prod
EOF
cat > $d/overlays/prod/replicas.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notes
spec:
  replicas: 2
EOF
cat > $d/overlays/prod/kustomization.yaml <<EOF
namespace: notes-prod
resources:
- namespace.yaml
- ../../base
patches:
- path: replicas.yaml
EOF
printf "LOG_LEVEL=info\nNOTES_STORAGE=s3\nMAX_NOTE_KB=256\n" > $d/overlays/prod/settings.env
chown -R student:student $d
rm -rf /root/.dojo/notes-base-original && cp -r $d/base /root/.dojo/notes-base-original'

source /root/exam/bin/lib.sh
on dojo1 'export KUBECONFIG=/etc/kubernetes/admin.conf; cd /home/student/answers/m1-07 && openssl genrsa -out dana.key 2048 2>/dev/null && openssl req -new -key dana.key -subj "/CN=dana" -out dana.csr
cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dana
spec:
  request: $(base64 -w0 < dana.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: [client auth]
EOF
kubectl certificate approve dana
for i in $(seq 20); do c=$(kubectl get csr dana -o jsonpath="{.status.certificate}"); [ -n "$c" ] && break; sleep 1; done
echo "$c" | base64 -d > dana.crt
k="kubectl config --kubeconfig dana.kubeconfig"
$k set-cluster dojo1 --server=https://dojo1-control-plane:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs
$k set-credentials dana --client-key=dana.key --client-certificate=dana.crt --embed-certs
$k set-context dana@dojo1 --cluster=dojo1 --user=dana --namespace=dev
$k use-context dana@dojo1
chown -R student:student .'
kc dojo1 -n dev create role pod-editor --verb=get,list,create,delete --resource=pods
kc dojo1 -n dev create rolebinding dana-pod-editor --role=pod-editor --user=dana

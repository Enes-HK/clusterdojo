**What this tests:** the full path from a key to a working user: the CSR API, a kubeconfig built by hand, and RBAC for a user (not a ServiceAccount).

**1. Key and CSR**

```bash
cd /home/student/answers/m1-07
openssl genrsa -out dana.key 2048
openssl req -new -key dana.key -subj "/CN=dana" -out dana.csr
```

The CN becomes the user name Kubernetes sees. (An `O=` field would become a group.)

**2. CertificateSigningRequest** (the example on the "Certificate Signing Requests" page, "Normal user"):

```bash
cat <<EOF | k apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: dana
spec:
  request: $(base64 -w0 < dana.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
EOF
k certificate approve dana
k get csr dana -o jsonpath='{.status.certificate}' | base64 -d > dana.crt
```

**3. kubeconfig**

```bash
k config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}'     # https://dojo1-control-plane:6443
k config --kubeconfig dana.kubeconfig set-cluster dojo1 --server=https://dojo1-control-plane:6443 \
  --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs
k config --kubeconfig dana.kubeconfig set-credentials dana --client-key=dana.key --client-certificate=dana.crt --embed-certs
k config --kubeconfig dana.kubeconfig set-context dana@dojo1 --cluster=dojo1 --user=dana --namespace=dev
k config --kubeconfig dana.kubeconfig use-context dana@dojo1
```

**4. RBAC**

```bash
k -n dev create role pod-editor --verb=get,list,create,delete --resource=pods
k -n dev create rolebinding dana-pod-editor --role=pod-editor --user=dana
k auth can-i delete pods -n dev --as=dana            # yes
k auth can-i get pods -n default --as=dana           # no
k --kubeconfig dana.kubeconfig get pods              # notes
```

**Traps**
- `request:` must be the base64 of the whole CSR file in one line (`base64 -w0`).
- Without `--embed-certs` the kubeconfig only stores file paths. That works here, but breaks as soon as the file is copied elsewhere.
- `--user=dana`, not `--serviceaccount`: a certificate user isn't a ServiceAccount.

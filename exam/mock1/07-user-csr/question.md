---
title: A new user with a client certificate
host: dojo1
docs: https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/ | Certificate Signing Requests ; https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/ | kubeconfig ; https://kubernetes.io/docs/reference/access-authn-authz/rbac/ | RBAC
---
> Target: 10 minutes

The new developer `dana` needs access to this cluster. Work in `/home/student/answers/m1-07/` on `dojo1`.

1. Create a private key `dana.key` and a certificate signing request `dana.csr` for the user `dana` (common name `dana`)
2. Create a CertificateSigningRequest named `dana` from it, for client authentication against the API server, valid for one day. Approve it and save the issued certificate as `dana.crt`
3. Create the kubeconfig file `dana.kubeconfig` with a cluster (this cluster's API server and CA), the user `dana` (with key and certificate) and a context `dana@dojo1` that uses Namespace `dev`. Make that context the current one
4. `dana` may `get`, `list`, `create` and `delete` Pods in Namespace `dev`, and nothing else. Use a Role `pod-editor` and a RoleBinding `dana-pod-editor`

`kubectl --kubeconfig /home/student/answers/m1-07/dana.kubeconfig get pods` must work.

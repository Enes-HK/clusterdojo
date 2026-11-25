---
title: A leaked join token
host: dojo3
docs: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-token/ | kubeadm token ; https://kubernetes.io/docs/reference/access-authn-authz/bootstrap-tokens/ | Bootstrap Tokens ; https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/ | kubeadm join
---
> Target: 5 minutes

A bootstrap token of this cluster was pasted into a public chat. Its description says so.

1. Delete that token. The other tokens must stay.
2. Create a new token that expires after **2 hours**, with the description `worker-batch-3`.
3. Write the complete `kubeadm join` command a new worker would run with that token into `/home/student/answers/m2-08/join.sh`. It must include the CA certificate hash.

You need root on the instance: `sudo -i`.

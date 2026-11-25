**What this tests:** bootstrap tokens and the `kubeadm token` commands.

```bash
sudo -i
kubeadm token list
# TOKEN                     TTL     ...  DESCRIPTION
# h5n2b8.r1t6...            23h          bootstrap for worker-batch-2
# q7w2er.8k3m...            <forever>    node autoscaler, do not delete
# zx81kd.4hf7...            47h          pasted into #general chat by mistake
kubeadm token delete zx81kd
```

`--print-join-command` creates the token and prints the whole join command, with the endpoint and the CA hash:

```bash
kubeadm token create --ttl 2h --description worker-batch-3 --print-join-command > /home/student/answers/m2-08/join.sh
cat /home/student/answers/m2-08/join.sh
# kubeadm join dojo3-control-plane:6443 --token abc123.... --discovery-token-ca-cert-hash sha256:5f0e...
kubeadm token list
```

**By hand**, the CA hash is the SHA-256 of the CA's public key:

```bash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der | openssl dgst -sha256 -hex
```

A bootstrap token is a Secret `bootstrap-token-<id>` in `kube-system`, so `k -n kube-system get secret` shows them as well. Deleting that Secret also deletes the token.

**Traps**
- The token ID (the part before the dot) is enough for `kubeadm token delete`.
- `--ttl 0` means the token never expires. The default TTL is 24 hours.

**What this tests:** reading what the service tells you, and noticing that the second error is a different kind.

**How to get there:**

```bash
ssh dojo3-node1
sudo -i
systemctl status kubelet        # status=203/EXEC, and the Drop-In path
```

`203/EXEC` means systemd couldn't start the program, so kubelet never ran. Compare the `ExecStart=` line with the real binary:

```bash
which kubelet                   # /usr/bin/kubelet
vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf     # ExecStart=/usr/bin/kubelet ...
systemctl daemon-reload
systemctl restart kubelet
systemctl status kubelet        # now status=1/FAILURE
```

`1/FAILURE` means kubelet **did** start, then quit by itself. The reason is in its log, not in systemd:

```bash
journalctl -u kubelet -n 30 --no-pager
# failed to load Kubelet config file ... /var/lib/kubelet/config.yml: no such file
ls /var/lib/kubelet/            # the real name is config.yaml
vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf     # --config=/var/lib/kubelet/config.yaml
systemctl daemon-reload
systemctl restart kubelet
systemctl is-active kubelet
```

Back on the control plane:

```bash
exit; exit
ssh dojo3
echo 203/EXEC > /home/student/answers/m2-01/status
k run worker-probe --image=nginx:1-alpine --dry-run=client -o yaml > p.yaml
vim p.yaml                      # under spec: nodeName: dojo3-worker
k apply -f p.yaml
k get pod worker-probe -o wide
```

**Traps**
- After editing a unit or drop-in, run `systemctl daemon-reload`. Without it, systemd keeps using the old text.
- Nothing here is an apiserver problem. Stay on the node until kubelet is `active`.
- The drop-in path differs between setups, so read it from `systemctl status` rather than memorising it.

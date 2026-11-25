**What this tests:** the node troubleshooting routine. NotReady almost always means the **kubelet** on that node isn't talking to the API server.

```bash
ssh dojo3
k get node                               # dojo3-worker NotReady
k describe node dojo3-worker | grep -A5 Conditions    # "Kubelet stopped posting node status"
exit; ssh dojo3-node1                  # or from dojo3: ssh dojo3-node1
sudo -i

systemctl status kubelet                 # inactive (dead) + "disabled"
systemctl start kubelet; systemctl status kubelet
journalctl -u kubelet -n 30 --no-pager   # "/usr/local/bin/kubelet: No such file or directory"
which kubelet                            # /usr/bin/kubelet
systemctl cat kubelet                    # shows the unit AND its drop-ins, with file paths
vim /etc/systemd/system/kubelet.service.d/10-kubeadm.conf   # ExecStart=/usr/bin/kubelet ...
systemctl daemon-reload                  # after every unit file change!
systemctl enable --now kubelet           # enable = after reboot, --now = start it now
```
Back on dojo3: `k get node` shows Ready after a few seconds.

**The routine for any node problem:** `systemctl status kubelet` → `journalctl -u kubelet` → `systemctl cat kubelet` (where is the config?) → fix → `daemon-reload` → `restart`.

**Traps**
- Only `systemctl start`: it runs now but is still **disabled**, so it's gone after a reboot. `is-enabled` must say `enabled`.
- Editing the unit file without `systemctl daemon-reload`. systemd keeps using the old version.
- The `ExecStart=` empty line in the drop-in is **intentional**. It clears the main unit's ExecStart before setting a new one. Don't delete it.

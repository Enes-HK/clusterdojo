**What this tests:** static Pods, mirror Pods, and finding where a kubelet reads its static Pods from.

The name ends in the node name and the Pod is owned by the Node, so it's a mirror Pod of a static Pod:

```bash
k get pod node-debugger-dojo1-worker -o jsonpath='{.metadata.ownerReferences}'    # kind: Node
k get pod node-debugger-dojo1-worker -o yaml | grep -A2 annotations                # kubernetes.io/config.source: file
```

Deleting a mirror Pod only deletes the API object. The kubelet still runs the Pod from its manifest file and recreates the mirror. The file has to go:

```bash
ssh dojo1-node1
sudo -i
ls /etc/kubernetes/manifests/                     # empty, so not the default folder
ps aux | grep kubelet                             # --config=/var/lib/kubelet/config.yaml
grep staticPodPath /var/lib/kubelet/config.yaml   # staticPodPath: /etc/kubelet.d
grep -l node-debugger /etc/kubelet.d/*
rm /etc/kubelet.d/node-tools.yaml
```

The kubelet notices within a few seconds, stops the container and removes the mirror Pod:

```bash
crictl pods --name node-debugger                  # gone (NotReady, then removed)
exit; exit
k get pod node-debugger-dojo1-worker              # NotFound
```

**Traps**
- The file name doesn't have to match the Pod name. Search the folder for the name.
- Setting `staticPodPath` back to the default would hide the Pod too, but the task says not to change the kubelet configuration, and the file would still be there.

source /root/exam/bin/lib.sh
m=/etc/kubernetes/manifests/kube-apiserver.yaml
answers dojo4 m1-02
# break only the livenessProbe port: the apiserver starts fine, then gets killed every ~1.5 minutes
on dojo4 "sed -i '/livenessProbe:/,/port:/ s/port: probe-port/port: 6444/' $m && grep -n -A8 livenessProbe $m"

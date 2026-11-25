source /root/exam/bin/lib.sh
on dojo4 "sed -i '/livenessProbe:/,/port:/ s/port: 6444/port: probe-port/' /etc/kubernetes/manifests/kube-apiserver.yaml"
echo 'spec.containers[].livenessProbe.httpGet.port' | put dojo4 /home/student/answers/m1-02/field
sleep 60

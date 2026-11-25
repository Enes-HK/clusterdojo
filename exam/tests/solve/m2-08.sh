source /root/exam/bin/lib.sh
on dojo3 "kubeadm token delete zx81kd && kubeadm token create --ttl 2h --description worker-batch-3 --print-join-command > $ANS/m2-08/join.sh && cat $ANS/m2-08/join.sh"

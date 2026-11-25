source /root/exam/bin/lib.sh
kc dojo1 delete csr dana --ignore-not-found
drop_ns dojo1 dev
kc dojo1 create ns dev
kc dojo1 -n dev run notes --image=busybox:1 --restart=Never -- sleep 1d
answers dojo1 m1-07

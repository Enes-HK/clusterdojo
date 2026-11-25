source /root/exam/bin/lib.sh
drop_ns dojo2 payroll
kc dojo2 create ns payroll
kc dojo2 -n payroll create secret generic pg-credentials --from-literal=username=payroll_rw --from-literal=password=t0p-s3cret-42
kc dojo2 -n payroll create configmap payslip-config --from-literal=payroll.ini='currency=EUR'

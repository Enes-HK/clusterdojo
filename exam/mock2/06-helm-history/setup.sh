source /root/exam/bin/lib.sh
repo=/root/exam/charts-repo
drop_ns dojo2 streaming streaming-labs
kc dojo2 create ns streaming
answers dojo2 m2-06
# the question says repo "acme" is configured for student on dojo2
on dojo2 "sudo -iu student bash -c 'helm repo add acme http://charts.acme:8879 --force-update && helm repo update acme'"
hc dojo2 -n streaming install jukebox $repo/webapp-1.0.0.tgz --set banner="Live Now" --set service.port=8090
hc dojo2 -n streaming install broadcast $repo/webapp-1.2.0.tgz --set banner="Tune In"
kc dojo2 -n streaming rollout status deploy/broadcast --timeout=90s
hc dojo2 -n streaming upgrade broadcast $repo/webapp-1.2.0.tgz --reuse-values --set image.tag=0.0.0-missing
hc dojo2 -n streaming ls -a

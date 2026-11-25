source /root/exam/bin/lib.sh
h() { on dojo2 "sudo -iu student helm $*"; }
h get values jukebox -n streaming '>' /home/student/answers/m2-06/jukebox-values.yaml
h upgrade jukebox acme/webapp -n streaming --version 1.2.0 --reuse-values --set replicaCount=3
h rollback broadcast 1 -n streaming
h install audiobook acme/webapp -n streaming-labs --create-namespace --version 1.0.0 --set service.type=NodePort
kc dojo2 -n streaming rollout status deploy/jukebox --timeout=90s
kc dojo2 -n streaming rollout status deploy/broadcast --timeout=90s

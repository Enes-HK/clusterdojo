source /root/exam/bin/lib.sh
drop_ns dojo2 payments data
kc dojo2 create ns payments
kc dojo2 create ns data
# echo <ns> <name> <port>: an HTTP server that answers "<name>-ok" (or the given text)
echo_srv() {
  kc dojo2 -n "$1" create deploy "$2" --image=hashicorp/http-echo:1.0 -- /http-echo -text="${4:-$2-ok}" -listen=:$3
  kc dojo2 -n "$1" expose deploy "$2" --port=$3
}
echo_srv data db 5432
echo_srv data cache 6379
# same label app=db, but in payments itself: a podSelector without namespaceSelector would allow it
echo_srv payments db 5432 local-db
echo_srv payments web 8080 payments-web
kc dojo2 -n payments create deploy api --image=busybox:1 -- sleep 1d
for d in db cache; do kc dojo2 -n data rollout status deploy/$d --timeout=90s; done
for d in db web api; do kc dojo2 -n payments rollout status deploy/$d --timeout=90s; done

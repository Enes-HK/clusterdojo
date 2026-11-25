# Helpers shared by setup.sh and grade.sh scripts. Runs as root inside the "terminal" container.
EXAM=/root/exam

# Linux hosts (start.sh sets HOST_UID/HOST_GID): whatever a script wrote into the mounted exam/ (chart repos,
# state, results) is handed back to the user who owns exam/ when the script ends, so nothing is left owned by root.
give_back() { [ -n "${HOST_UID:-}" ] && chown -R "$HOST_UID:${HOST_GID:-$HOST_UID}" "$EXAM/state" "$EXAM/results" "$EXAM/charts-repo" 2>/dev/null; return 0; }
trap give_back EXIT

# kubectl / helm against a cluster by its name: kc dojo1 get pods -A
kc() { local c=$1; shift; kubectl --kubeconfig "$EXAM/kubeconfigs/$c" "$@"; }
hc() { local c=$1; shift; helm --kubeconfig "$EXAM/kubeconfigs/$c" "$@"; }

# run a command as root on an exam host: on dojo1-node1 systemctl is-active kubelet
on() { local h=$1; shift; ssh -o ConnectTimeout=10 "$h" "$@"; }

# answer files live in the student's home on the instance the task names
ANS=/home/student/answers
# answers <host> <id>: an empty answer folder for one task, owned by student
answers() { on "$1" "rm -rf $ANS/$2 && mkdir -p $ANS/$2 && chown -R student:student $ANS"; }

# copy stdin into a file on a host: echo hi | put dojo1 /home/student/answers/m1-06/x
put() { on "$1" "mkdir -p \"\$(dirname '$2')\" && cat > '$2'"; }

# Pods of a selector that are not terminating (a rollout can leave old Pods around for a while)
# live <cluster> <namespace> <selector> [jq field, default .metadata.name] -> one value per line
live() { kc "$1" -n "$2" get pod -l "$3" -o json 2>/dev/null   | jq -r ".items[] | select(.metadata.deletionTimestamp==null) | ${4:-.metadata.name}"; }

# grading output: one line per check, read by server.py
pass() { echo "PASS|$1"; }
fail() { echo "FAIL|$1|${2:-}"; }
check() { local d=$1; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }

# throwaway pod for in-cluster tests, pinned to the control plane node (so a broken worker can't block it);
# prints command output, returns 0 if the command succeeded. probe <cluster> <namespace> <image> <labels> -- cmd...
# (not "run -i --rm": that can delete the Pod before its output was read)
probe() {
  local c=$1 ns=$2 img=$3 labels=$4 n="probe-$RANDOM$RANDOM" ph=""; shift 5
  kc "$c" -n "$ns" run "$n" --image="$img" --labels="$labels" --restart=Never \
    --overrides="{\"spec\":{\"nodeName\":\"$c-control-plane\"}}" --command -- "$@" >/dev/null 2>&1 || return 1
  for _ in $(seq 120); do
    ph=$(kc "$c" -n "$ns" get pod "$n" -o jsonpath='{.status.phase}' 2>/dev/null)
    case $ph in Succeeded|Failed) break ;; esac; sleep 1
  done
  kc "$c" -n "$ns" logs "$n" 2>/dev/null
  kc "$c" -n "$ns" delete pod "$n" --wait=false >/dev/null 2>&1
  [ "$ph" = Succeeded ]
}

# delete Namespaces and wait until they are gone: drop_ns <cluster> <namespace>...
# An unavailable aggregated API (metrics-server broken by a task) keeps a Namespace in Terminating although all
# its content is removed. Only in that case the deletion is finished directly.
drop_ns() {
  local c=$1 ns; shift
  kc "$c" delete ns "$@" --ignore-not-found --wait=false >/dev/null
  for ns in "$@"; do
    for _ in $(seq 180); do
      kc "$c" get ns "$ns" -o json > /tmp/drop-ns.json 2>/dev/null || break
      if jq -e '[.status.conditions[]? | select(
            (.type=="NamespaceDeletionDiscoveryFailure" and .status=="True") or
            (.type=="NamespaceContentRemaining" and .status=="False") or
            (.type=="NamespaceFinalizersRemaining" and .status=="False"))] | length == 3' /tmp/drop-ns.json >/dev/null; then
        jq '.spec.finalizers=[]' /tmp/drop-ns.json | kc "$c" replace --raw "/api/v1/namespaces/$ns/finalize" -f - >/dev/null
      fi
      sleep 1
    done
  done
}

# wait until a command succeeds (max seconds)
wait_for() { local t=$1; shift; for _ in $(seq "$t"); do "$@" >/dev/null 2>&1 && return 0; sleep 1; done; return 1; }

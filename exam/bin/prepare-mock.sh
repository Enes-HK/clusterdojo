#!/bin/bash
# Prepares one mock exam: puts the clusters back into a clean state (heal.sh), then runs every task's setup.sh.
# Usage: bash prepare-mock.sh 1|2      (the exam UI calls it when you switch mocks or start a mock again)
source /root/exam/bin/lib.sh
cd "$EXAM" || exit 1
m=${1:-1}
[ -d "mock$m" ] || { echo "no mock$m"; exit 1; }
log() { echo "[mock $m $(date +%T)] $*"; }

mkdir -p state/old
echo "$m" > state/mock.txt
rm -f state/setup-done
date > state/preparing
# a new attempt: the timer and stopwatches of the previous attempt of this mock go to state/old
[ -f "state/exam-m$m.json" ] && mv "state/exam-m$m.json" "state/old/exam-m$m-$(date +%Y%m%d-%H%M%S).json"

log "putting nodes and control planes back into a clean state"
bash "$EXAM/bin/heal.sh"

# tasks that break a node, a control plane component or a cluster add-on go last ("setup: last" in question.md),
# so the other tasks can still create their Pods
first=$(for d in mock$m/*/; do grep -q '^setup: last' "$d/question.md" || basename "$d"; done)
last=$(for d in mock$m/*/; do grep -q '^setup: last' "$d/question.md" && basename "$d"; done)
for t in $first $last; do
  log "task $t"
  bash "mock$m/$t/setup.sh" > "state/setup-m$m-$t.log" 2>&1 || echo "  !! setup of $t failed, see state/setup-m$m-$t.log"
done

echo "$m" > state/setup-done
rm -f state/preparing
log "done"   # lib.sh hands state/ back to the host user on exit (Linux)

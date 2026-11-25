#!/bin/bash
# Proves tasks are solvable and can be set up again, one task at a time:
#   setup -> grade (should fail) -> reference solve -> grade (must be full) -> setup again -> grade -> solve again
# The last solve leaves the task solved, so node faults never pile up for the next task.
# Usage: M=1 bash verify.sh 1 2 14      (tasks of mock 1)      M=2 bash verify.sh all      (every task of mock 2)
# One summary line per task on stdout; details in /tmp/verify-m<M>-<nn>.*
M=${M:-1}
qdir=/root/exam/mock$M
[ -d "$qdir" ] || { echo "no $qdir"; exit 1; }
[ "$1" = all ] && set -- $(ls "$qdir" | cut -d- -f1)
for n in "$@"; do
  nn=$(printf %02d "${n#0}"); d=$(ls -d $qdir/${nn}-* 2>/dev/null | head -1)
  id=m$M-$nn
  [ -z "$d" ] && { echo "$id: no task folder"; continue; }
  solve=/root/exam/tests/solve/$id.sh
  log=/tmp/verify-$id
  g() { timeout 300 bash $d/grade.sh 2>/dev/null > $log.$1; echo "$(grep -c '^PASS' $log.$1)/$(grep -c '^PASS\|^FAIL' $log.$1)"; }
  t0=$(date +%s)
  bash $d/setup.sh > $log.setup 2>&1; s1=$?
  before=$(g before)
  bash $solve > $log.solve 2>&1; so=$?
  after=$(g after)
  bash $d/setup.sh > $log.setup2 2>&1; s2=$?
  again=$(g again)
  bash $solve > $log.solve2 2>&1
  echo "$id $(basename $d) | setup=$s1 unsolved=$before solve=$so solved=$after | setup2=$s2 again=$again | $(( $(date +%s) - t0 ))s"
  grep '^FAIL' $log.after | sed 's/^/     after: /'
done

source /root/exam/bin/lib.sh
kc dojo3 get ns reports >/dev/null 2>&1 && fail "Namespace reports is gone" "phase: $(kc dojo3 get ns reports -o jsonpath='{.status.phase}')" || pass "Namespace reports is gone"
kc dojo3 get crd reportjobs.reports.example.com >/dev/null 2>&1 && pass "CRD reportjobs.reports.example.com still exists" || fail "CRD reportjobs.reports.example.com still exists"
f=$(on dojo3 "cat /home/student/answers/m1-09/finalizer 2>/dev/null" | tr -d '[:space:]')
[ "$f" = reports.example.com/archive-before-delete ] && pass "Finalizer: reports.example.com/archive-before-delete" \
  || fail "Finalizer: reports.example.com/archive-before-delete" "found: ${f:-nothing}"

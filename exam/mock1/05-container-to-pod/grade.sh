source /root/exam/bin/lib.sh
A=/home/student/answers/m1-05
o=$(on dojo3 "cat $A/owner 2>/dev/null" | tr -d '[:space:]')
[ "$o" = ops-tools/audit-sync/uploader ] && pass "Owner: ops-tools/audit-sync/uploader" || fail "Owner: ops-tools/audit-sync/uploader" "found: ${o:-nothing}"
i=$(on dojo3 "cat $A/image 2>/dev/null" | tr -d '[:space:]')
[ "$i" = busybox:1.36 ] && pass "Image: busybox:1.36" || fail "Image: busybox:1.36" "found: ${i:-nothing}"
[ "$(kc dojo3 -n ops-tools get pods --no-headers 2>/dev/null | grep -c Running)" = 3 ] && pass "Nothing deleted" || fail "Nothing deleted"

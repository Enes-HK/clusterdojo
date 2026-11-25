source /root/exam/bin/lib.sh
A=/home/student/answers/m1-04
pod=$(live dojo1 billing app=invoice-worker | head -1)
# while the crashed instance is still the current one (state terminated, back-off) plain logs show it;
# once a new instance runs, the crashed one is --previous. Retry until the file has the crash output.
for _ in $(seq 20); do
  st=$(kc dojo1 -n billing get pod "$pod" -o jsonpath='{.status.containerStatuses[0].state}')
  if echo "$st" | grep -q terminated; then prev=""; else prev="--previous"; fi
  kc dojo1 -n billing logs "$pod" $prev > /tmp/m1-04-previous.log 2>/dev/null
  grep -q starting /tmp/m1-04-previous.log && ! grep -q 'waiting for jobs' /tmp/m1-04-previous.log && break
  sleep 2
done
put dojo1 $A/previous.log < /tmp/m1-04-previous.log
kc dojo1 -n billing get pod "$pod" -o json | jq -r '.status.containerStatuses[0] | (.state.terminated // .lastState.terminated) | "\(.reason)/\(.exitCode)"' | put dojo1 $A/termination
kc dojo1 -n billing set resources deploy/invoice-worker -c worker --requests=memory=64Mi --limits=memory=128Mi
kc dojo1 -n billing rollout status deploy/invoice-worker --timeout=120s
sleep 10

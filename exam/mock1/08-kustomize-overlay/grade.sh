source /root/exam/bin/lib.sh
D=/home/student/notes-app
on dojo2 "diff -r /root/.dojo/notes-base-original $D/base" >/dev/null 2>&1 && pass "Base unchanged" || fail "Base unchanged"
k=$(on dojo2 "cat $D/overlays/prod/kustomization.yaml 2>/dev/null")
echo "$k" | grep -q '^images:' && echo "$k" | grep -q 'configMapGenerator:' \
  && pass "Overlay uses images and configMapGenerator" || fail "Overlay uses images and configMapGenerator"
on dojo2 "grep -qx 'LOG_LEVEL=debug' $D/overlays/prod/settings.env" && pass "settings.env has LOG_LEVEL=debug" || fail "settings.env has LOG_LEVEL=debug"

kc dojo2 -n notes-prod rollout status deploy/notes --timeout=30s >/dev/null 2>&1
d=$(kc dojo2 -n notes-prod get deploy notes -o json 2>/dev/null)
[ "$(echo "$d" | jq -r '.spec.template.spec.containers[0].image')" = nginx:1.29-alpine ] && [ "$(echo "$d" | jq -r .status.readyReplicas)" = 2 ] \
  && pass "notes runs nginx:1.29-alpine with 2 ready replicas" || fail "notes runs nginx:1.29-alpine with 2 ready replicas"
cm=$(echo "$d" | jq -r '.spec.template.spec.containers[0].envFrom[]?.configMapRef.name // empty' | head -1)
[[ "$cm" == notes-config-* ]] && pass "envFrom uses the generated ConfigMap ($cm)" || fail "envFrom uses the generated ConfigMap (notes-config-<hash>)" "found: ${cm:-none}"
envs=$(kc dojo2 -n notes-prod exec deploy/notes -- env 2>/dev/null)
echo "$envs" | grep -qx LOG_LEVEL=debug && echo "$envs" | grep -qx NOTES_STORAGE=s3 && echo "$envs" | grep -qx MAX_NOTE_KB=256 \
  && pass "Running Pods have all keys, LOG_LEVEL=debug" || fail "Running Pods have all keys, LOG_LEVEL=debug" "$(echo "$envs" | grep -E 'LOG_LEVEL|NOTES|MAX_NOTE' | xargs)"
[ "$(kc dojo2 -n notes-prod get cm -o name 2>/dev/null | grep -c 'configmap/notes-config-')" -ge 2 ] \
  && pass "The change created a new ConfigMap (hash suffix) and rolled the Pods" || fail "The change created a new ConfigMap (hash suffix) and rolled the Pods"

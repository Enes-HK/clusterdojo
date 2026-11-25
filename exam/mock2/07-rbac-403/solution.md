**What this tests:** reading a Role and a RoleBinding critically, and `kubectl auth can-i --as`.

```bash
SA=system:serviceaccount:ci:deployer
k auth can-i create deployments -n apps-staging --as $SA          # no
k -n apps-staging get role,rolebinding deployer -o yaml
```

Two things are wrong:

- The Role's rule is for `apiGroups: [""]`, the core group. Deployments are in group `apps`, so that rule never matches.
- The RoleBinding's subject is ServiceAccount `deployer` in Namespace `default`, not `ci`.

The Role also grants `get`/`list` on Secrets, which has to go.

```bash
k -n apps-staging edit role deployer
```

```yaml
rules:
- apiGroups: [apps]
  resources: [deployments]
  verbs: [get, list, create, update, delete]
```

```bash
k -n apps-staging edit rolebinding deployer
```

```yaml
subjects:
- kind: ServiceAccount
  name: deployer
  namespace: ci
```

Check, then answer:

```bash
k auth can-i delete deployments -n apps-staging --as $SA          # yes
k auth can-i get secrets -n apps-staging --as $SA                 # no
k auth can-i create deployments -n apps-prod --as $SA             # yes (!)
k auth can-i --list -n apps-prod --as $SA
k -n apps-prod get rolebinding -o wide                            # ci-release: Group system:serviceaccounts:ci -> edit
printf 'yes\nno\nyes\n' > /home/student/answers/m2-07/can-i
```

The third answer is `yes`: RoleBinding `ci-release` in `apps-prod` gives ClusterRole `edit` to the group `system:serviceaccounts:ci`, which every ServiceAccount in Namespace `ci` belongs to.

**Traps**
- `--as` needs the full name `system:serviceaccount:<namespace>:<name>`. With just `deployer` you ask about a user called deployer.
- A RoleBinding's `roleRef` can't be changed, but its `subjects` can.
- Deleting and recreating the RoleBinding with `kubectl create rolebinding ... --serviceaccount=ci:deployer` is fine too, as long as the names stay the same.

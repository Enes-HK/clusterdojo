source /root/exam/bin/lib.sh
answers dojo4 m2-07
drop_ns dojo4 ci apps-staging apps-prod
kc dojo4 create ns ci
kc dojo4 create ns apps-staging
kc dojo4 create ns apps-prod
kc dojo4 -n ci create sa deployer
kc dojo4 -n ci create sa linter
kc dojo4 apply -f - <<'EOF'
# fault 1: Deployments are in API group "apps", not the core group; and the Secrets rule doesn't belong here
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: deployer, namespace: apps-staging}
rules:
- apiGroups: [""]
  resources: [deployments]
  verbs: [get, list, create, update, delete]
- apiGroups: [""]
  resources: [secrets]
  verbs: [get, list]
---
# fault 2: the subject points to a ServiceAccount in the wrong Namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: deployer, namespace: apps-staging}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: deployer}
subjects:
- {kind: ServiceAccount, name: deployer, namespace: default}
---
# not part of the fix: every ServiceAccount of Namespace ci may edit apps-prod (a group binding)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: ci-release, namespace: apps-prod}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: edit}
subjects:
- {kind: Group, name: "system:serviceaccounts:ci", apiGroup: rbac.authorization.k8s.io}
EOF

---
title: A pipeline gets 403 Forbidden
host: dojo4
docs: https://kubernetes.io/docs/reference/access-authn-authz/rbac/ | Using RBAC Authorization ; https://kubernetes.io/docs/reference/kubectl/generated/kubectl_auth/kubectl_auth_can-i/ | kubectl auth can-i
---
> Target: 7 minutes

The deploy pipeline runs as ServiceAccount `deployer` in Namespace `ci`. It should manage Deployments in Namespace `apps-staging`, but every attempt ends with `403 Forbidden`.

1. Fix the existing Role `deployer` and RoleBinding `deployer` in `apps-staging`, so the ServiceAccount can `get`, `list`, `create`, `update` and `delete` Deployments there. Don't create other Roles or bindings.
2. The Role must grant nothing beyond that.
3. Answer these questions for ServiceAccount `deployer`, **after** your fix, one line each with `yes` or `no`, into `/home/student/answers/m2-07/can-i`:
    1. Can it delete Deployments in `apps-staging`?
    2. Can it read Secrets in `apps-staging`?
    3. Can it create Deployments in `apps-prod`?

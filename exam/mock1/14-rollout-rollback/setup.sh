source /root/exam/bin/lib.sh
answers dojo1 m1-14
drop_ns dojo1 shop
kc dojo1 create ns shop
# rev <change-cause> <image> <env as flow yaml>: one revision of checkout
rev() {
kc dojo1 apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: shop
  annotations: {kubernetes.io/change-cause: "$1"}
spec:
  replicas: 3
  strategy: {type: RollingUpdate, rollingUpdate: {maxSurge: 0, maxUnavailable: 2}}
  selector: {matchLabels: {app: checkout}}
  template:
    metadata: {labels: {app: checkout}}
    spec:
      containers:
      - name: web
        image: $2
        env: $3
EOF
}
rev "initial release" nginx:1-alpine '[]'
kc dojo1 -n shop rollout status deploy/checkout --timeout=120s
rev "enable cart v2" nginx:1-alpine '[{name: FEATURE_CART, value: v2}]'
kc dojo1 -n shop rollout status deploy/checkout --timeout=120s
rev "switch payments to stripe" nginx:1-alpine '[{name: FEATURE_CART, value: v2}, {name: PAYMENT_PROVIDER, value: stripe}]'
kc dojo1 -n shop rollout status deploy/checkout --timeout=120s
# the broken one: a typo in the image tag, and someone paused the rollout afterwards
rev "nginx patch update" nginx:1-alpline '[{name: FEATURE_CART, value: v2}, {name: PAYMENT_PROVIDER, value: stripe}]'
wait_for 60 bash -c "kubectl --kubeconfig $EXAM/kubeconfigs/dojo1 -n shop get pod -l app=checkout | grep -q -e ErrImagePull -e ImagePullBackOff"
kc dojo1 -n shop rollout pause deploy/checkout

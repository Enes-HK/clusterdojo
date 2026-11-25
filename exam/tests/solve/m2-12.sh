source /root/exam/bin/lib.sh
kc dojo1 label ns storefront gateway-access=granted --overwrite
kc dojo1 -n backends patch referencegrant storefront-to-catalog --type=json -p '[{"op":"replace","path":"/spec/from/0/namespace","value":"storefront"}]'
ip=$(kc dojo1 -n edge get svc shared-gw-nginx -o jsonpath='{.spec.clusterIP}')
wait_for 60 on dojo1 "curl -s -m 2 -H 'Host: store.local' http://$ip/ | grep -q catalog-api-ok"

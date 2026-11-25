source /root/exam/bin/lib.sh
drop_ns dojo1 news gateway-infra
kc dojo1 create ns gateway-infra
kc dojo1 create ns news
for s in main preview catalog catalog-beta status; do
  kc dojo1 -n news create deploy $s --image=hashicorp/http-echo:1.0 -- /http-echo -text="$s" -listen=:5678
  kc dojo1 -n news expose deploy $s --port=80 --target-port=5678
done
d=$(mktemp -d)
openssl req -x509 -newkey rsa:2048 -nodes -days 30 -keyout $d/tls.key -out $d/tls.crt -subj '/CN=*.example.org' -addext 'subjectAltName=DNS:*.example.org'
kc dojo1 -n gateway-infra create secret tls public-tls --cert=$d/tls.crt --key=$d/tls.key
rm -rf $d
for s in main preview catalog catalog-beta status; do kc dojo1 -n news rollout status deploy/$s --timeout=90s; done

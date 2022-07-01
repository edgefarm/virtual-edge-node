# virtual-edge-node

# Prerequisites
https://github.com/FiloSottile/mkcert


kubectl get secrets -n kubeedge kubeedge-ca -o 'go-template={{index .data "tls.crt"}}' | base64 -d > example/.env/ca/rootCA.pem
kubectl get secrets -n kubeedge kubeedge-ca -o 'go-template={{index .data "tls.key"}}' | base64 -d > example/.env/ca/rootCA-key.pem
CAROOT=$(pwd)/ca mkcert -client -cert-file example/.env/node/node.pem -key-file example/.env/node/node.key "*.nip.io" "*.edgefarm.local" "cloudcore.kubeedge.svc.cluster.local"

# Modify and run the example

..
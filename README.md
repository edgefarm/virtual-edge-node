# virtual-edge-node

# Prerequisites

For this to work you need the following up and running:
* running kubernetes cluster with `edgefarm.core`
* `kubectl` configured to your cluster
* `kustomize` installed

# Quick start 

## Prerequisites

You need `mkcert` installed on your system. Follow the installation steps on the [mkcert github repo](https://github.com/FiloSottile/mkcert#installation).

## Prepare certificates

Run the following commands to create all necessary certificates:

```sh
kubectl get secrets -n kubeedge kubeedge-ca -o 'go-template={{index .data "tls.crt"}}' | base64 -d > example/.env/ca/rootCA.pem
kubectl get secrets -n kubeedge kubeedge-ca -o 'go-template={{index .data "tls.key"}}' | base64 -d > example/.env/ca/rootCA-key.pem
CAROOT=example/.env/ca mkcert -client -cert-file example/.env/node/node.pem -key-file example/.env/node/node.key "*.nip.io" "*.edgefarm.local" "cloudcore.kubeedge.svc.cluster.local"
```

## Modify and run the example

Customize `example/kustomization.yaml` to your needs.

Deploy the example using kustomize.

```sh
kustomize build example | kubectl apply -f -
```

See the pods that represent the virtual nodes and the nodes itself

```sh
$ kubectl get pods -n virtual-edge-nodes
NAME                                 READY   STATUS    RESTARTS   AGE
virtual-edge-node-569d5bddd6-hzfp9   1/1     Running   0          24m
virtual-edge-node-569d5bddd6-mrq6r   1/1     Running   0          24m
virtual-edge-node-569d5bddd6-sgx64   1/1     Running   0          24m

$ kubectl get nodes
NAME                                 STATUS   ROLES                  AGE     VERSION
kind-edgefarm-core-control-plane     Ready    control-plane,master   7h11m   v1.21.12
virtual-edge-node-569d5bddd6-hzfp9   Ready    agent,edge             24m     v1.19.3-kubeedge-v1.9.1
virtual-edge-node-569d5bddd6-mrq6r   Ready    agent,edge             24m     v1.19.3-kubeedge-v1.9.1
virtual-edge-node-569d5bddd6-sgx64   Ready    agent,edge             24m     v1.19.3-kubeedge-v1.9.1

$ kubectl top nodes
NAME                                 CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
kind-edgefarm-core-control-plane     389m         3%     3233Mi          8%        
virtual-edge-node-569d5bddd6-hzfp9   25m          0%     151Mi           0%        
virtual-edge-node-569d5bddd6-mrq6r   29m          0%     154Mi           0%        
virtual-edge-node-569d5bddd6-sgx64   26m          0%     149Mi           0%
```

Congratulations! You've just created three virtual nodes that are fully operational.
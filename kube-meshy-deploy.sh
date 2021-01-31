#! /bin/bash

set -e 

REGISTRY_NAME="private-registry"
REGISTRY_EXT_PORT="5000"
KIND_CLUSTER_NAME="kube-1.19.1"

if [ `docker ps -f ancestor=registry:2 -q | wc -l | tr -d ' '` -eq 0 ]; 
then 
echo "Deploy Private Docker Registry"

docker run -d --restart=always -p "${REGISTRY_EXT_PORT}:5000" --name "${REGISTRY_NAME}" registry:2
fi

echo
echo "Start KinD cluster"

kind create cluster  --name "${KIND_CLUSTER_NAME}" --config kind-configs/config.yaml

echo
echo "Waiting Kubernetes online.."

KUBEURL=$(kubectl cluster-info|sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g' | awk '/master/{print $6}')

while [[ $(curl -k --silent --output /dev/null --write-out "%{http_code}" $KUBEURL) != "403" ]]; do
    printf '.'
    sleep 5
done

echo
echo "Kube UP!"
kubectl get nodes

echo
echo "Deploy Nginx-ingress"
kubectl apply -f nginx-ingress/nginx-ingress-deploy.yaml

echo
echo "Wait for Nginx-ingress controller to be ready."
POD=$(kubectl -n ingress-nginx get pods | awk '/contr/{print $1}')

while [ "$(kubectl -n ingress-nginx get pod ${POD} -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; do
    printf '.'
    sleep 5
done

echo -e '\033[32m

Done! Now you can deploy everything you want.
Have a look to README file..

\033[0m'

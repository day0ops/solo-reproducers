#!/usr/bin/env bash

SCRIPT_NAME="`basename $0`"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

b64enc() { openssl enc -base64 -A; }

kubectl create ns apps-configuration
envsubst < <(cat $DIR/workspaces.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/vg.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/rt.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/ext-auth-server.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/ext-auth-policy.yaml) | kubectl apply -f -

gwaddr=$(kubectl get -n gloo-mesh-gateways svc/istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

apikey="$(openssl rand -base64 12)"
export API_KEY=$(printf %s "$apikey" | b64enc)

envsubst < <(cat $DIR/secret.yaml) | kubectl apply -f -

printf "\n%s\n" "Restarting ext-auth-service to load the changes"
kubectl rollout restart deploy/ext-auth-service -n gloo-mesh

# give it enough time to restart and settle
sleep 20

printf "\n\n%s\n\n" "------> First test run <------"

curl -iv -o /dev/null -w "%{http_code}" \
    -H "api-key-01: ${apikey}" -H "api-key-02: ${apikey}" \
    $gwaddr
status_code=$(curl -o /dev/null -w "%{http_code}" \
    -H "api-key-01: ${apikey}" -H "api-key-02: ${apikey}" \
    $gwaddr)

if [[ "$status_code" = "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

# ---------------------------------------------------------------------------------------------------------------------

printf "\n\n%s\n\n" "------> Second test run <------"

apikey="$(openssl rand -base64 12)"
export API_KEY=$(printf %s "$apikey" | b64enc)

envsubst < <(cat $DIR/secret.yaml) | kubectl apply -f -

sleep 5

curl -iv -o /dev/null -w "%{http_code}" \
    -H "api-key-01: ${apikey}" -H "api-key-02: ${apikey}" \
    $gwaddr
status_code=$(curl -o /dev/null -w "%{http_code}" \
    -H "api-key-01: ${apikey}" -H "api-key-02: ${apikey}" \
    $gwaddr)

if [[ "$status_code" == "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

#!/usr/bin/env bash

SCRIPT_NAME="`basename $0`"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

kubectl port-forward deploy/mock-jwt -n jwt-server 8008 > /dev/null 2>&1 &
mock_pid=$!

trap '{
    kill $mock_pid
}' EXIT

sleep 3

access_token=$(curl -s \
    -XPOST localhost:8008/token | jq -r .access_token)

gwaddr=$(minikube service -p testing gloo-proxy-main-gw -n apps --url=true)

# ---------------------------------------------------------------------------------------------------------------------

printf "\n\n%s\n\n" "------> First test run <------"

kubectl apply -f $DIR/jwks-upstream.yaml

sleep 5

curl -ivs -o /dev/null -w "%{http_code}" \
    -H "access-token: ${access_token}" \
    $gwaddr
status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "access-token: ${access_token}" \
    $gwaddr)

if [[ "$status_code" = "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

# ---------------------------------------------------------------------------------------------------------------------

printf "\n\n%s\n\n" "------> Second test run <------"

kubectl apply -f $DIR/jwks-upstream-through-squid-tunnel.yaml

sleep 5

curl -ivs -o /dev/null -w "%{http_code}" \
    -H "access-token: ${access_token}" \
    $gwaddr
status_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "access-token: ${access_token}" \
    $gwaddr)

if [[ "$status_code" = "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi


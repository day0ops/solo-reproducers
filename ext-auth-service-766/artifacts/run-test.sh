#!/usr/bin/env bash

SCRIPT_NAME="`basename $0`"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

digest() { openssl dgst -sha256 -hmac $1 -binary; }
b64enc() { openssl enc -base64 -A; }

hmac_gen_signature() {
    local secret=$1
    local verb=$2
    local path=$3
    local protocol=$4
    local -n headers_array=$5

    local header_str=$(for i in ${!headers_array[@]}; do echo $i":" ${headers_array[$i]}" "; done)
    header_str=$(echo $header_str)

    local signing_str="$header_str\n$verb $path $protocol"

    signature="$(printf "$signing_str" | digest $secret | b64enc)"
    echo $signature
}

declare -A headers

# Set of headers we'l pass
headers["foo"]="bar"

kubectl create ns apps-configuration
envsubst < <(cat $DIR/workspaces.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/vg.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/rt.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/ext-auth-server.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/ext-auth-policy.yaml) | kubectl apply -f -

gwaddr=$(kubectl get -n gloo-mesh-gateways svc/istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

username="joe.blogg"
secret="$(openssl rand -base64 12)"
export USERNAME=$(printf %s "$username" | b64enc)
export SECRET=$(printf %s "$secret" | b64enc)

envsubst < <(cat $DIR/secret.yaml) | kubectl apply -f -

printf "\n%s\n" "Restarting ext-auth-service to load the changes"
kubectl rollout restart deploy/ext-auth-service -n gloo-mesh

# give it enough time to restart and settle
sleep 20

printf "\n\n%s\n\n" "------> First test run <------"

signature=$(hmac_gen_signature $secret "GET" "/" "HTTP/1.1" headers)
authorization="hmac username=\"$username\", algorithm=\"hmac-sha256\", headers=\"${!headers[@]} @request-target\", signature=\"$signature\""

curl -iv -o /dev/null -w "%{http_code}" -H "foo: bar" \
    -H "Authorization: ${authorization}" \
    $gwaddr
status_code=$(curl -o /dev/null -w "%{http_code}" -H "foo: bar" \
    -H "Authorization: ${authorization}" \
    $gwaddr)

if [[ "$status_code" = "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

# ---------------------------------------------------------------------------------------------------------------------

printf "\n\n%s\n\n" "------> Second test run <------"

username="joe.blogg"
secret="$(openssl rand -base64 12)"
export USERNAME=$(printf %s "$username" | b64enc)
export SECRET=$(printf %s "$secret" | b64enc)

envsubst < <(cat $DIR/secret.yaml) | kubectl apply -f -

sleep 5

signature=$(hmac_gen_signature $secret "GET" "/" "HTTP/1.1" headers)
authorization="hmac username=\"$username\", algorithm=\"hmac-sha256\", headers=\"${!headers[@]} @request-target\", signature=\"$signature\""

curl -iv -o /dev/null -w "%{http_code}" -H "foo: bar" \
    -H "Authorization: ${authorization}" \
    $gwaddr
status_code=$(curl -o /dev/null -w "%{http_code}" -H "foo: bar" \
    -H "Authorization: ${authorization}" \
    $gwaddr)

if [[ "$status_code" == "200" ]]; then
    printf "\n%s\n" "------> Result: success <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

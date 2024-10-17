#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

kubectl delete -n apps-configuration -f $DIR/configuration/secret.yaml

sleep 10

vs_status=$(kubectl get vs -n apps-configuration main-vs -o jsonpath='{.status.statuses.gloo-system.state}')
gw_status=$(kubectl get gw -n gloo-system gateway-proxy -o jsonpath='{.status.statuses.gloo-system.state}')

if [[ "$vs_status" != "Accepted" || "$gw_status" != "Accepted" ]]; then
    printf "\n%s\n" "------> Result: pass <------"
else
    printf "\n%s\n" "------> Result: fail <------"
fi

if kubectl logs deploy/gloo -n gloo-system | grep -q "Proxy had invalid config after xds sanitization"; then
    printf "\n%s\n" "------> Found snapshot translator warning for missing secret in the Gloo log <------"
fi
#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

wait_for_pods_to_exist() {
    local ns=$1
    local pod_label=$2
    local max_wait_secs=$3
    local interval_secs=2
    local start_time
    start_time=$(date +%s)

    while true; do
        current_time=$(date +%s)
        if (( (current_time - start_time) > max_wait_secs )); then
            echo "Waited for pods in namespace \"$ns\" with name prefix \"$pod_label\" to exist for $max_wait_secs seconds without luck. Returning with error."
            return 1
        fi

        if [[ $(kubectl get pods -l "$pod_label" -n $ns -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; then
            sleep $interval_secs
        else
            echo "Pods in namespace \"$ns\" with name prefix \"$pod_label\" exist."
            break
        fi
    done
}

# ----------- install 2.5.9

export GLOO_MESH_HELM_VERSION=2.5.9
export CLUSTER_NAME=demo

helm repo add gloo-platform https://storage.googleapis.com/gloo-platform/helm-charts
helm repo update gloo-platform

helm upgrade -i gloo-platform-crds gloo-platform/gloo-platform-crds \
    -n gloo-mesh \
    --create-namespace \
    --version=$GLOO_MESH_HELM_VERSION

helm upgrade -i gloo-platform gloo-platform/gloo-platform \
    -n gloo-mesh \
    --version $GLOO_MESH_HELM_VERSION \
    --values install/helm-values.yaml \
    --set common.cluster=$CLUSTER_NAME \
    --set licensing.glooGatewayLicenseKey=$GLOO_PLATFORM_GLOO_GATEWAY_LICENSE_KEY

wait_for_pods_to_exist "gloo-mesh-gateways" "app=istio-ingressgateway" 200

kubectl create ns apps-configuration
envsubst < <(cat $DIR/apps/httpbin-deploy.yaml) | kubectl apply -f -

envsubst < <(cat $DIR/artifacts/workspaces.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/rl-settings.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/rl-client-config.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/rl-server-config.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/vg.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/parent-rt.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/child-rt.yaml) | kubectl apply -f -
envsubst < <(cat $DIR/artifacts/rl-policy.yaml) | kubectl apply -f -

sleep 5

if [[ $(kubectl get -n apps-configuration RateLimitServerSettings rl-server -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
    echo "----> RateLimitServerSettings 'rl-server' does not have status or its not Accepted"
fi

if [[ $(kubectl get -n gloo-mesh RateLimitServerConfig rl-server-config -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
    echo "----> RateLimitServerConfig 'rl-server-config' does not have status or its not Accepted"
fi

if [[ $(kubectl get -n apps-configuration RateLimitClientConfig rl-client-config -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
    echo "----> RateLimitClientConfig 'rl-client-config' does not have status or its not Accepted"
fi

# # ----------- upgrade to 2.6.2

# export GLOO_MESH_HELM_VERSION=2.6.2

# helm upgrade -i gloo-platform-crds gloo-platform/gloo-platform-crds \
#     -n gloo-mesh \
#     --create-namespace \
#     --version=$GLOO_MESH_HELM_VERSION

# helm upgrade -i gloo-platform gloo-platform/gloo-platform \
#     -n gloo-mesh \
#     --version $GLOO_MESH_HELM_VERSION \
#     --values install/helm-values.yaml \
#     --set common.cluster=$CLUSTER_NAME \
#     --set licensing.glooGatewayLicenseKey=$GLOO_PLATFORM_GLOO_GATEWAY_LICENSE_KEY

# sleep 60

# wait_for_pods_to_exist "gloo-mesh" "app=gloo-mesh-mgmt-server" 200

# if [[ $(kubectl get -n apps-configuration RateLimitServerSettings rl-server -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
#     echo "----> RateLimitServerSettings 'rl-server' does not have status or its not Accepted"
# fi

# if [[ $(kubectl get -n gloo-mesh RateLimitServerConfig rl-server-config -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
#     echo "----> RateLimitServerConfig 'rl-server-config' does not have status or its not Accepted"
# fi

# if [[ $(kubectl get -n apps-configuration RateLimitClientConfig rl-client-config -o jsonpath='{.status.common.State.approval}') != "ACCEPTED" ]]; then
#     echo "----> RateLimitClientConfig 'rl-client-config' does not have status or its not Accepted"
# fi
#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

GLOO_GW_HELM_VERSION="1.16.4"

helm repo add gloo-ee https://storage.googleapis.com/gloo-ee-helm
helm repo update gloo-ee --fail-on-repo-update-fail

envsubst < <(cat $DIR/helm-override-values.yaml) | helm upgrade -i gloo-ee gloo-ee/gloo-ee \
  --namespace gloo-system \
  --create-namespace \
  --version ${GLOO_GW_HELM_VERSION} \
  --set-string license_key=${GLOO_EDGE_LICENSE_KEY} \
  -f -

kubectl rollout status deploy/gloo -n gloo-system

sleep 10

kubectl create ns apps
kubectl create ns apps-configuration

kubectl apply -n apps -f $DIR/configuration/httpbin-deploy.yaml

kubectl apply -n apps-configuration -f $DIR/configuration/secret.yaml
kubectl apply -n apps-configuration -f $DIR/configuration/vs.yaml
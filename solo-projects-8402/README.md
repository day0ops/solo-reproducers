# Repro for solo-projects/8402

1. Environment setup.

    ```bash
    minikube start -p testing
    ```

2. Setting up Gloo Gateway.

    ```bash
    export GLOO_GW_HELM_VERSION="1.19.2"
    export GLOO_GW_LICENSE_KEY="Gloo Gateway Enterprise license>"

    helm repo add gloo-ee https://storage.googleapis.com/gloo-ee-helm
    helm repo update gloo-ee --fail-on-repo-update-fail

    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

    envsubst < <(cat ./helm-override-values.yaml) | helm upgrade -i gloo-ee gloo-ee/gloo-ee \
      --namespace gloo-system \
      --create-namespace \
      --version=${GLOO_GW_HELM_VERSION} \
      --set-string license_key=${GLOO_GW_LICENSE_KEY} \
      -f -
    ```

3. Deploy the artifacts.

    ```bash
    ./artifacts/apply.sh -a
    ```

4. Check the listeners.

    ```bash
    kubectl port-forward deploy/gloo-proxy-common-gw -n common-gw 19000 > /dev/null 2>&1 &
    pid=$!
    curl -iv localhost:19000/listeners
    kill -9 $pid
    ```
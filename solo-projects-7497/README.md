# Repro for solo-projects/7497

This repro basically demonstrates that despite of defining `httpProxyHostname` in the `Upstream` the tunnel to squid proxy is never initiated. This is also obvious in the raw Envoy configuration as Gloo should be generating a `solo_io_generated_self_listener_*` cluster to pipe the traffic but it never does.

An example of this missing cluster is,
```json
    {
     "name": "solo_io_generated_self_listener_example_default",
     "active_state": {
      "version_info": "1890341140479409906",
      "listener": {
       "@type": "type.googleapis.com/envoy.config.listener.v3.Listener",
       "name": "solo_io_generated_self_listener_example_default",
       "address": {
        "pipe": {
         "path": "@/example_default"
        }
       },
       "filter_chains": [
        {
         "filters": [
          {
           "name": "tcp",
           "typed_config": {
            "@type": "type.googleapis.com/envoy.extensions.filters.network.tcp_proxy.v3.TcpProxy",
            "stat_prefix": "soloioTcpStatsexample_default",
            "cluster": "example_default",
            "tunneling_config": {
             "hostname": "www.example.com:80"
            }
           }
          }
         ]
        }
       ]
      }
     }
    }
```

1. Environment setup.

    ```bash
    minikube start -p testing
    ```

    Make sure to create a tunnel here to access the Gloo service as a LoadBalancer from host.

2. Setting up Gloo Gateway.

    ```bash
    export GLOO_GW_HELM_VERSION="1.18.8"
    export GLOO_GW_LICENSE_KEY="Gloo Gateway Enterprise license>"

    helm repo add gloo-ee https://storage.googleapis.com/gloo-ee-helm
    helm repo update gloo-ee --fail-on-repo-update-fail

    kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

    envsubst < <(cat ./helm-override-values.yaml) | helm upgrade -i gloo-ee gloo-ee/gloo-ee \
      --namespace gloo-system \
      --create-namespace \
      --version=${GLOO_GW_HELM_VERSION} \
      --set-string license_key=${GLOO_GW_LICENSE_KEY} \
      -f -

    ## below instructions are for the dev builds with the fixes
    # export GLOO_GW_HELM_VERSION="1.19.0-beta5-bmain-5ed95a7"

    # helm repo add gloo-ee-test https://storage.googleapis.com/gloo-ee-test-helm
    # helm repo update gloo-ee-test --fail-on-repo-update-fail

    # kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml
    # envsubst < <(cat ./helm-override-values.yaml) | helm upgrade -i gloo-ee gloo-ee-test/gloo-ee \
    #  --namespace gloo-system \
    #  --create-namespace \
    #  --version=${GLOO_GW_HELM_VERSION} \
    #  --set-string license_key=${GLOO_GW_LICENSE_KEY} \
    #  -f -
    ```

3. Install Squid.

    ```bash
    kubectl apply -f squid/deploy.yaml
    ```

4. Install the jwt mock service.

    ```bash
    kubectl apply -f mock-jwt-server/deploy.yaml
    ```

5. Deploy configuration including the sample app.

    ```bash
    ./artifacts/apply-config.sh -a
    ```

6. Run the tests.

    > Note: second test should fail due to problems with squid proxy tunnel.

    ```bash
    ./artifacts/run-tests.sh
    ```
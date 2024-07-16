# Reproducer for ext-auth-service/766

1. Environment setup

    ```
    colima start --runtime containerd -p eas-766 -c 4 -m 8 -d 20 --network-address --install-metallb --metallb-address-pool "192.168.106.100/32" --kubernetes --kubernetes-disable traefik,servicelb --kubernetes-version v1.29.5+k3s1
    ```

2. Install Gloo Edge 1.16.

    ```
    export GLOO_MESH_HELM_VERSION=2.5.8
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
    ```

3. Run the tests with,

    ```
    ./artifacts/run-test.sh
    ```

    which should result in the following tests,

    ```
    ------> First test run <------

    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 192.168.106.100:80...
    * Connected to 192.168.106.100 (192.168.106.100) port 80
    > GET / HTTP/1.1
    > Host: 192.168.106.100
    > User-Agent: curl/8.6.0
    > Accept: */*
    > foo: bar
    > Authorization: hmac username="joe.blogg", algorithm="hmac-sha256", headers="foo @request-target", signature="SS+Oyayz2cC1zcrEhRRHTCcT9emxzaDBeOE/S1il2NE="
    >
    < HTTP/1.1 200 OK
    < content-length: 6
    < content-type: text/plain
    < date: Tue, 16 Jul 2024 13:19:06 GMT
    < server: istio-envoy
    <
    { [6 bytes data]
    100     6  100     6    0     0    837      0 --:--:-- --:--:-- --:--:--   857
    * Connection #0 to host 192.168.106.100 left intact
    200  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100     6  100     6    0     0    962      0 --:--:-- --:--:-- --:--:--  1000

    ------> Result: success <------


    ------> Second test run <------

    secret/hmac-digest configured
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 192.168.106.100:80...
    * Connected to 192.168.106.100 (192.168.106.100) port 80
    > GET / HTTP/1.1
    > Host: 192.168.106.100
    > User-Agent: curl/8.6.0
    > Accept: */*
    > foo: bar
    > Authorization: hmac username="joe.blogg", algorithm="hmac-sha256", headers="foo @request-target", signature="fPi8rH+2AwLSqBz6kfNsJKp9+7b3jZNCyl0W8ih3ElQ="
    >
    < HTTP/1.1 401 Unauthorized
    < www-authenticate: HMAC signature missing or invalid
    < date: Tue, 16 Jul 2024 13:19:11 GMT
    < server: istio-envoy
    < content-length: 0
    <
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    * Connection #0 to host 192.168.106.100 left intact
    401  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0

    ------> Result: fail <------
    ```
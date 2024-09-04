# Reproducer for ext-auth-service/769

1. Environment setup

    ```
    colima start --runtime containerd -p eas-766 -c 4 -m 8 -d 20 --network-address --install-metallb --metallb-address-pool "192.168.106.100/32" --kubernetes --kubernetes-disable traefik,servicelb --kubernetes-version v1.29.5+k3s1
    ```

2. Install Gloo Mesh Gateway `2.5.8`.

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
    > api-key-01: BYHEAttOQvHqXP3g
    > api-key-02: BYHEAttOQvHqXP3g
    >
    < HTTP/1.1 200 OK
    < content-length: 6
    < content-type: text/plain
    < date: Mon, 22 Jul 2024 12:23:23 GMT
    < server: istio-envoy
    <
    { [6 bytes data]
    100     6  100     6    0     0    930      0 --:--:-- --:--:-- --:--:--  1000
    * Connection #0 to host 192.168.106.100 left intact
    200  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    100     6  100     6    0     0    948      0 --:--:-- --:--:-- --:--:--  1000

    ------> Result: success <------


    ------> Second test run <------

    secret/api-key-main configured
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0*   Trying 192.168.106.100:80...
    * Connected to 192.168.106.100 (192.168.106.100) port 80
    > GET / HTTP/1.1
    > Host: 192.168.106.100
    > User-Agent: curl/8.6.0
    > Accept: */*
    > api-key-01: R/LFRQzQWvV7aR/Y
    > api-key-02: R/LFRQzQWvV7aR/Y
    >
    < HTTP/1.1 403 Forbidden
    < date: Mon, 22 Jul 2024 12:23:29 GMT
    < server: istio-envoy
    < content-length: 0
    <
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
    * Connection #0 to host 192.168.106.100 left intact
    403  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
    0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0

    ------> Result: fail <------
    ```

    Last test is failing with `403` due to the changes to the secret which ext auth service never reconciles.
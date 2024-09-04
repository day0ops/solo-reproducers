# Reproducer for gloo-mesh-enterprise/18490

This shows the missing status in `RateLimitClientConfig` and `RateLimitServerSettings` resources.

1. Environment setup

    ```
    colima start -p rl-issue -r containerd -c 4 -m 8 -d 20 --network-address -k --kubernetes-version v1.29.8+k3s1
    ```

2. Run `apply.sh` to deploy everything.

    ```
    ./apply.sh
    ```
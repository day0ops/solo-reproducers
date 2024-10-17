# Reproducer for gloo/10210

1. Environment setup

```bash
colima start -p gloo-10210 -r containerd -c 4 -m 8 -d 20 --network-address -k --kubernetes-version v1.29.8+k3s1
```

2. Run setup

```bash
./install.sh
```

3. Run the tests with,

```bash
./test.sh
```

which should result in,

```bash
------> Result: fail <------

------> Found snapshot translator warning for missing secret in the Gloo log <------
```
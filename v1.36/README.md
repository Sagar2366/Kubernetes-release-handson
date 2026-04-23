# Kubernetes v1.36 "Haru"

**70 enhancements** | [Official Blog](https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/) | [Full Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.36.md)

## Features Covered

| # | Feature | Stage | Demo? |
|---|---------|-------|-------|
| 01 | [In-Place Pod Vertical Scaling](01-inplace-pod-resize/) | Beta | Live demo |
| 02 | [User Namespaces in Pods](02-user-namespaces/) | GA | Live demo |
| 03 | [HPA Scale-to-Zero](03-hpa-scale-to-zero/) | Alpha | Live demo (with load generation) |
| 04 | [OCI VolumeSource](04-oci-volumesource/) | GA | Live demo |
| 05 | [MutatingAdmissionPolicy (CEL)](05-mutating-admission-policy/) | GA | Live demo |
| 06 | [DRA GPU Scheduling](06-dra-gpu-scheduling/) | GA+Beta | YAML walkthrough (no GPU needed) |

## Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) v0.20+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.36+
- [jq](https://jqlang.github.io/jq/download/) (for JSON output formatting)
- Docker Desktop running

## Quick Start

```bash
# 1. Create the kind cluster (single cluster for ALL demos)
./00-kind-cluster/create-cluster.sh

# 2. Run any demo
./01-inplace-pod-resize/demo.sh
./02-user-namespaces/demo.sh
./04-oci-volumesource/demo.sh
./05-mutating-admission-policy/demo.sh
./03-hpa-scale-to-zero/demo.sh    # Run last -- needs load generation time

# 3. Clean up
./00-kind-cluster/cleanup.sh
```

## Folder Structure

```
├── 00-kind-cluster/                        # Cluster setup (run FIRST)
│   ├── kind-config.yaml                    # Single cluster config (all features)
│   ├── create-cluster.sh                   # Creates cluster + installs metrics-server
│   └── cleanup.sh                          # Deletes the cluster
│
├── 01-inplace-pod-resize/                  # Resize pods WITHOUT restart
│   ├── deploy.yaml                         # Deployment with initial resources
│   └── demo.sh                             # Proves container ID unchanged after resize
│
├── 02-user-namespaces/                     # Root in container != root on host
│   ├── pod-no-userns.yaml                  # Baseline: no user namespaces
│   ├── pod-with-userns.yaml                # hostUsers: false
│   └── demo.sh                             # kubectl debug node/ to prove UID mapping
│
├── 03-hpa-scale-to-zero/                   # HPA scales to 0 replicas
│   ├── deploy.yaml                         # Deployment + Service (hpa-example image)
│   ├── hpa.yaml                            # HPA with minReplicas: 0
│   └── demo.sh                             # Load gen -> scale up -> stop -> scale to 0
│
├── 04-oci-volumesource/                    # Mount OCI image as volume
│   ├── pod-oci-volume.yaml                 # Pod with OCI artifact mounted
│   └── demo.sh                             # Shows mounted content
│
├── 05-mutating-admission-policy/           # CEL-based mutation, no webhooks
│   ├── policy-add-label.yaml               # Policy + Binding (injects env: dev)
│   ├── test-pod.yaml                       # Test pod to verify injection
│   └── demo.sh                             # Apply policy, create pod, verify label
│
└── 06-dra-gpu-scheduling/                  # YAML reference only (needs GPU hardware)
    ├── README.md                           # Explains what each file shows
    ├── resourceclaim-prioritized.yaml      # H100 -> A100 -> 2xT4 fallback
    ├── device-taint-rule.yaml              # Quarantine degraded GPUs
    ├── resourceclaim-mig-partition.yaml    # MIG partition request
    └── pod-with-gpu.yaml                   # Pod referencing a ResourceClaim
```

## Recommended Demo Order

1. `00-kind-cluster/create-cluster.sh` -- create the cluster
2. **Demo 01** -- In-Place Pod Resize (quick, visual)
3. **Demo 02** -- User Namespaces (security story)
4. **Demo 04** -- OCI VolumeSource (short, clean)
5. **Demo 05** -- MutatingAdmissionPolicy (platform story)
6. **Demo 06** -- DRA YAML walkthrough (on-screen, no cluster)
7. **Demo 03** -- HPA Scale-to-Zero (last -- needs load + cooldown time)

## Key Documentation Links

| Feature | Kubernetes Docs | KEP |
|---------|----------------|-----|
| In-Place Pod Resize | [Resize Container Resources](https://kubernetes.io/docs/concepts/workloads/pods/resize-container-resources/) | [KEP #1287](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/1287-in-place-update-pod-resources) |
| User Namespaces | [User Namespaces](https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/) | [KEP #127](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/127-user-namespaces) |
| HPA Scale-to-Zero | [Horizontal Pod Autoscale](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) | [KEP #2021](https://github.com/kubernetes/enhancements/tree/master/keps/sig-autoscaling/2021-hpa-scale-to-zero) |
| OCI VolumeSource | [Image Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#image) | [KEP #4639](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/4639-oci-volume-source) |
| MutatingAdmissionPolicy | [Admission Controllers](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/) | [KEP #3962](https://github.com/kubernetes/enhancements/tree/master/keps/sig-api-machinery/3962-mutating-admission-policies) |
| DRA | [Dynamic Resource Allocation](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/) | [KEP #4816](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/4816-dra-prioritized-alternatives) |

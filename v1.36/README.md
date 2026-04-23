# Kubernetes v1.36 "Haru"

**70 enhancements** | [Official Blog](https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/) | [Full Changelog](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.36.md) | [Upgrade Guide (v1.35 → v1.36)](UPGRADE-GUIDE.md)

## Features Covered

| # | Feature | Stage | Demo? |
|---|---------|-------|-------|
| 01 | [In-Place Pod Vertical Scaling](01-inplace-pod-resize/) | Beta | Live demo |
| 02 | [User Namespaces in Pods](02-user-namespaces/) | GA | Live demo |
| 03 | [HPA Scale-to-Zero](03-hpa-scale-to-zero/) | Alpha | Live demo (with load generation) |
| 04 | [OCI VolumeSource](04-oci-volumesource/) | GA | Live demo |
| 05 | [MutatingAdmissionPolicy (CEL)](05-mutating-admission-policy/) | GA | Live demo |
| 06 | [DRA GPU Scheduling](06-dra-gpu-scheduling/) | GA+Beta | YAML walkthrough (no GPU needed) |

### 01 - In-Place Pod Vertical Scaling (Beta)

Change a running pod's CPU/memory requests and limits **without restarting the container**. The container ID stays the same, connections are preserved, and there's zero downtime. Previously, any resource change required deleting and recreating the pod.

### 02 - User Namespaces in Pods (GA)

Run containers as `root` inside the pod while mapping to an **unprivileged UID on the host**. A container compromise no longer gives the attacker root on the node. Enable with `hostUsers: false` in the pod spec -- no cluster-wide config needed.

### 03 - HPA Scale-to-Zero (Alpha)

The Horizontal Pod Autoscaler can now scale a Deployment all the way down to **zero replicas** when there's no traffic or load. Ideal for dev/staging environments, batch queues, and cost optimization. Requires the `HPAScaleToZero` feature gate.

### 04 - OCI VolumeSource (GA)

Mount any OCI image as a **read-only volume** inside a pod, completely independent of the application container image. Use cases include ML model weights, config bundles, static assets, and plugin JARs -- no more initContainer + wget + emptyDir hacks.

### 05 - MutatingAdmissionPolicy (GA)

Define mutation rules using **CEL expressions** directly in the API, replacing the need for webhook servers. No binary to build, no Deployment to manage, no TLS certificates to rotate. The example injects a default `env: dev` label on matching resources.

### 06 - DRA GPU Scheduling (GA + Beta)

Dynamic Resource Allocation brings structured device management to Kubernetes. New in 1.36: **prioritized alternatives** (fall back from H100 → A100 → 2xT4), **device taints** (quarantine degraded GPUs), and **partitionable devices** (MIG slices). Requires GPU hardware -- this folder contains reference YAMLs only.

Breaking: Metric Renames
"Two metrics got renamed to match Prometheus conventions:

volume_operation_total_errors --> volume_operation_errors_total
etcd_bookmark_counts --> etcd_bookmark_total
If you have dashboards or alerts on these, update them BEFORE upgrading."

Breaking: StrictIPCIDRValidation Enabled by Default
"IPs with leading zeros like 010.000.000.005 and ambiguous CIDRs like 192.168.0.5/24 are now REJECTED by the API server. If you have manifests or Helm charts with these patterns, they'll fail on 1.36."

Deprecation: Service externalIPs
"Service .spec.externalIPs is deprecated. This has been a security concern since CVE-2020-8554. Removal is planned for v1.43, so you have time, but start migrating now."

Removal: In-tree Portworx Plugin
"The in-tree Portworx volume plugin is gone. CSI migration is complete. If you're still on in-tree Portworx, you must migrate before upgrading."

Removal: gitRepo Volume Plugin
"gitRepo volumes are permanently disabled now. They were deprecated since v1.11 due to security risks -- the git clone runs as root. Use init containers instead."

Retirement: Ingress NGINX
"The SIG Network and Security Response Committee officially retired Ingress NGINX on March 24, 2026. If you haven't moved to Gateway API yet, the clock is ticking."

Other Breaking Changes
" - MaxUnavailableStatefulSet is disabled by default (regression fix)

Audit log rotation defaults changed -- maxage now 366 days
client-go AtomicFIFO changes informer timing behavior
Scheduler PreBind plugin API changed"

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

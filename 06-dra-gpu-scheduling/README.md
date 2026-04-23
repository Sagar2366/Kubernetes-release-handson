# DRA GPU Scheduling -- YAML Reference (Not Runnable Without GPU Hardware)

These YAML files are **reference examples** for the video walkthrough.
They require actual GPU hardware and DRA drivers (NVIDIA, Intel, AMD)
to run. Use them as on-screen visuals while explaining the concepts.

## Files

| File | Feature | Status | What It Shows |
|------|---------|--------|---------------|
| `resourceclaim-prioritized.yaml` | Prioritized Alternatives | **GA** | H100 -> A100 -> 2xT4 fallback |
| `device-taint-rule.yaml` | Device Taints | **Beta** | Quarantine GPUs with ECC errors |
| `resourceclaim-mig-partition.yaml` | Partitionable Devices | **Beta** | Request a MIG slice of an A100 |
| `pod-with-gpu.yaml` | DRA + PodResources API | **GA** | Pod referencing a ResourceClaim |

## What Graduated in 1.36

**GA (Stable):**
- [Prioritized Alternatives in Device Requests (KEP #4816)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/4816-dra-prioritized-alternatives)
- [PodResources API for DRA](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/device-plugins/#monitoring-device-plugin-resources)
- AdminAccess for ResourceClaims

**Beta (Enabled by Default):**
- [Device Taints and Tolerations (KEP #5055)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5055-scalable-dra-device-configuration)
- [Partitionable Devices (KEP #5004)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/5004-dra-partitionable-devices)
- [Consumable Capacity (KEP #4817)](https://github.com/kubernetes/enhancements/tree/master/keps/sig-node/4817-dra-scalable-capacity-tracking)
- Extended Resource support

## Key Documentation Links

- [DRA Overview](https://kubernetes.io/docs/concepts/scheduling-eviction/dynamic-resource-allocation/)
- [ResourceClaim API Reference](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/resource-claim-v1/)
- [CEL in Kubernetes](https://kubernetes.io/docs/reference/using-api/cel/)
- [NVIDIA DRA Driver](https://github.com/NVIDIA/k8s-dra-driver)
- [NVIDIA MIG User Guide](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/)
- [Container Device Interface (CDI)](https://github.com/cncf-tags/container-device-interface)
- [K8s 1.36 Release Blog](https://kubernetes.io/blog/2026/04/22/kubernetes-v1-36-release/)

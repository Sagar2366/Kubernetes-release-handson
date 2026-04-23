# Migrate from Kubernetes v1.35 → v1.36

Upgrading from 1.35 to 1.36 is a standard **minor upgrade**, but 1.36 tightens expectations around runtimes, autoscaling, and networking. Treat it like any production change: stage first, then prod.

---

## 1. Pre-upgrade Checklist

### a. Version skew & support

- Control plane and kubelets must be within **one minor version** of each other.
- Only upgrade **one minor at a time**: 1.35 → 1.36 is supported directly.

### b. Runtime & OS

- Ensure nodes are on a **supported container runtime**:
  - Prefer **containerd 2.x**; 1.36 is the last stop for older 1.6.x.
- Kernel:
  - Modern Linux with **cgroup v2**.
  - For PSI metrics: kernel compiled with `CONFIG_PSI=y`.

### c. Inventory features & add-ons

Note your use of:

- **Ingress-NGINX** (plan Gateway API migration separately).
- Any **alpha/beta features** in 1.35 (feature gates you enabled manually).
- **GPU / DRA** drivers, custom admission webhooks, and CNI/CSI plugins.

### d. Back up cluster state

- etcd snapshot (managed control planes: use cloud-provider tooling).
- Backup manifests / Helm values, CRDs, and admission policies.

---

## 2. Upgrade Strategy (Control Plane → Nodes → Workloads)

### Step 1: Upgrade the control plane

**kubeadm / self-managed:**

```bash
# On control-plane nodes
apt/yum update kubeadm kubelet kubectl to v1.36.x
kubeadm upgrade plan
kubeadm upgrade apply v1.36.x
systemctl restart kubelet
```

**Managed clusters (EKS/GKE/AKS):**

Use the provider's UI/CLI to upgrade the cluster / control plane to 1.36, then upgrade nodegroups. Always do this in **Dev/Staging** first.

### Step 2: Upgrade worker nodes

For each node group:

1. **Cordon + drain**:

   ```bash
   kubectl cordon <node>
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
   ```

2. Upgrade node OS packages / kubelet / containerd to 1.36-compatible versions.

3. **Restart kubelet** and bring node back:

   ```bash
   systemctl restart kubelet
   kubectl uncordon <node>
   ```

Repeat in small batches, watching:

```bash
kubectl get nodes
kubectl get pods -A
```

### Step 3: Verify core components

- All nodes `Ready`, all control-plane pods healthy.
- CNI, CSI, Ingress controllers, metrics-server, and cluster-autoscaler are running and logging cleanly.

---

## 3. Feature-specific Checks for 1.36

### a. HPA Scale-to-Zero

- If you plan to use `minReplicas: 0`:
  - Ensure `HPAScaleToZero` feature gate is **enabled**.
  - Confirm **metrics-server** is healthy.
  - Test on a non-critical Deployment — watch replicas scale up under load and back to `0` once idle.

### b. User Namespaces

- Enable on a **test namespace** first with `spec.hostUsers: false` on pods.
- Validate apps that touch hostPath, file ownership, or low-level Linux features still behave correctly.
- Gradually roll out via namespace-level policies or admission controllers.

### c. OCI VolumeSource

- Confirm nodes can pull from your OCI registry (Docker Hub, GHCR, ECR, etc.).
- Test an OCI volume-backed pod and validate read-only behavior.

### d. MutatingAdmissionPolicy

- If migrating from mutating webhooks:
  - Start with **non-destructive** CEL policies (e.g. label injection).
  - Watch admission latency and logs for errors.
  - Only decommission old webhooks after you confirm same behavior with MAP.

### e. DRA / GPU Environments

- Make sure **DRA-enabled drivers** are compatible with 1.36.
- In staging, test `firstAvailable` device preferences and PodResources API output.
- Monitor for scheduling or pod-start regressions.

---

## 4. Post-upgrade Validation

After all nodes are on 1.36:

- Run your **standard app smoke tests** (deployments, jobs, cronjobs).
- Verify:
  - Ingress / Gateway routing
  - HPA behavior (including scale to zero, if enabled)
  - Logs & metrics (PSI if kernel supports it)
- Review:

  ```bash
  kubectl get events -A
  ```

  Check controller logs (kube-controller-manager, scheduler, kubelet on a few nodes).

---

## 5. Rollback Plan (Have It Before You Upgrade)

If something goes wrong:

- **Control plane**: for kubeadm, use your etcd backup to restore the previous state. For managed clusters, use provider rollback if available.
- **Nodes**: you can roll individual nodes back to 1.35 (version skew allows N/N-1) while you investigate.

Keep the 1.35 node images / AMIs around until you're confident in 1.36 behavior in Prod.

---

## EKS-specific Upgrade Runbook

> If you run self-managed clusters, skip this section.

### Assumptions

- Cluster: **Amazon EKS**, currently **v1.35**
- You use **eksctl** or **Terraform/CloudFormation** for cluster + nodegroups
- You have at least **one non-prod (staging)** cluster that mirrors prod

### Step 1: Staging first

1. Pick your **staging EKS cluster** (same region, add-ons, node types, and IAM roles as prod).
2. Run the whole procedure below on staging: control plane → nodegroups → add-ons → validation.
3. Only when staging looks good, repeat for prod.

### Step 2: Upgrade the EKS control plane

```bash
CLUSTER=<cluster-name>
REGION=<region>

eksctl upgrade cluster \
  --name "$CLUSTER" \
  --region "$REGION" \
  --version 1.36 \
  --approve
```

Wait until complete:

```bash
aws eks describe-cluster \
  --name "$CLUSTER" \
  --region "$REGION" \
  --query 'cluster.version'
# should return "1.36"
```

Confirm from kubectl:

```bash
kubectl version
kubectl get nodes
```

You'll see control plane at 1.36 and nodes still at 1.35 — this skew is allowed temporarily.

### Step 3: Upgrade worker nodes via new nodegroups (blue/green)

#### 3a. Create a new 1.36 nodegroup

```bash
eksctl create nodegroup \
  --cluster "$CLUSTER" \
  --region "$REGION" \
  --name "${CLUSTER}-ng-136" \
  --node-type m5.large \
  --nodes 3 \
  --nodes-min 3 \
  --nodes-max 6 \
  --node-ami-family AmazonLinux2023 \
  --node-volume-size 50 \
  --version 1.36
```

Adjust type/count/ami-family to match your existing group. Wait for new nodes:

```bash
kubectl get nodes -o wide
# confirm new 1.36 nodes are Ready
```

#### 3b. Drain old nodegroup

```bash
NODE=<old-node-name>

kubectl cordon "$NODE"
kubectl drain "$NODE" \
  --ignore-daemonsets \
  --delete-emptydir-data
```

Workloads will move onto the new 1.36 nodes. Repeat for each old node.

#### 3c. Delete old nodegroup

Once all pods are off old nodes and tests pass:

```bash
eksctl delete nodegroup \
  --cluster "$CLUSTER" \
  --region "$REGION" \
  --name <old-nodegroup-name> \
  --approve
```

### Step 4: Upgrade EKS managed add-ons

Update **VPC CNI**, **CoreDNS**, and **kube-proxy** to versions recommended for 1.36.

```bash
# List add-ons
aws eks list-addons \
  --cluster-name "$CLUSTER" \
  --region "$REGION"

# Check available versions (example: vpc-cni)
aws eks describe-addon-versions \
  --addon-name vpc-cni \
  --kubernetes-version 1.36 \
  --region "$REGION" \
  --query 'addons[0].addonVersions[].addonVersion'

# Update each add-on
aws eks update-addon \
  --cluster-name "$CLUSTER" \
  --addon-name vpc-cni \
  --addon-version <LATEST_FOR_1_36> \
  --region "$REGION" \
  --resolve-conflicts OVERWRITE
```

Repeat for `coredns` and `kube-proxy`. Verify:

```bash
kubectl get pods -n kube-system
# all add-on pods should be Running
```

### Step 5: EKS post-upgrade validation

```bash
# Cluster health
kubectl get nodes                   # all Ready, v1.36.x
kubectl get pods -A                 # no CrashLoopBackOff in kube-system
```

App smoke tests:

- Ingress / Gateway routing works
- Deployments roll out
- CronJobs / Jobs run successfully
- HPA behavior: for any existing HPAs, confirm they still scale as expected

### EKS feature-specific notes

| Feature | EKS Notes |
|---------|-----------|
| **User Namespaces** | EKS AMIs have modern kernels; user namespaces generally work. Opt-in per pod with `hostUsers: false`. Test workloads that touch file permissions/hostPath first. |
| **OCI VolumeSource** | No EKS-specific config. Ensure nodes can reach your OCI registry (ECR, Docker Hub, etc.). |
| **MutatingAdmissionPolicy** | GA and available by default. Introduce CEL policies gradually; don't rip out existing webhooks on day 1. |
| **HPA Scale-to-Zero** | Whether `HPAScaleToZero` is enabled depends on the exact EKS patch level. Test in staging: create HPA with `minReplicas: 0`, generate load, verify 0→N→0. |
| **DRA / GPUs** | Only relevant for GPU node groups. Ensure GPU AMIs and drivers support 1.36. Test DRA behavior on a staging GPU cluster first. |

### EKS rollback posture

EKS does **not** support downgrading the control plane. Your safety net is:

- **Keeping old nodegroups** (1.35) until new ones are proven.
- Running the full migration in **staging** first.
- Using **IaC** (eksctl/Terraform configs) so you can recreate a 1.35 cluster if needed.

If issues appear after nodegroup migration, you can create a fresh **1.35 nodegroup** (control plane 1.36 + nodes 1.35 skew is allowed) and drain 1.36 nodes while you debug.

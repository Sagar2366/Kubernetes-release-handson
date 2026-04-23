#!/bin/bash
# Demo: User Namespaces in Pods (GA in 1.36)
# Proves root in container != root on host using kubectl debug node/
# Prerequisites: Run 00-kind-cluster/create-cluster.sh first
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "DEMO: User Namespaces in Pods"
echo "Kubernetes 1.36 - GA (Stable)"
echo "=========================================="
echo ""

# Step 1: Create namespace
echo ">>> Creating namespace..."
kubectl create ns userns-demo --dry-run=client -o yaml | kubectl apply -f -
echo ""

# Step 2: Deploy both pods
echo ">>> Deploying pod WITHOUT user namespaces (baseline)..."
kubectl apply -f "$SCRIPT_DIR/pod-no-userns.yaml"

echo ">>> Deploying pod WITH user namespaces (hostUsers: false)..."
kubectl apply -f "$SCRIPT_DIR/pod-with-userns.yaml"
echo ""

# Step 3: Wait
echo ">>> Waiting for pods to be ready..."
kubectl wait --for=condition=Ready pod/no-userns -n userns-demo --timeout=60s
kubectl wait --for=condition=Ready pod/with-userns -n userns-demo --timeout=60s
echo ""

# Pause for camera
echo ">>> Press ENTER to inspect the BASELINE pod (no user namespaces)..."
read -r

# Step 4: Inspect baseline pod
echo "=========================================="
echo "POD WITHOUT USER NAMESPACES (default)"
echo "=========================================="
echo ""
echo ">>> Inside the container:"
kubectl exec -n userns-demo no-userns -- sh -c '
  echo "id:"; id
  echo; echo "/proc/self/uid_map:"; cat /proc/self/uid_map
'
echo ""

echo ">>> On the host node (kubectl debug node/):"
NODE=$(kubectl get pod no-userns -n userns-demo -o jsonpath='{.spec.nodeName}')
echo ">>> Node: $NODE"
echo ">>> Look for the process -- it runs as UID 0 (root) on the host!"
echo ""
kubectl debug node/"$NODE" -it --image=busybox:1.36 -- chroot /host sh -c '
  echo "Processes matching no-userns:"
  ps aux | grep "sleep 3600" | grep -v grep | head -3
'
echo ""
echo ">>> Container root = Host root. Container escape = GAME OVER."
echo ""

# Pause for camera
echo ">>> Press ENTER to inspect the USER NAMESPACES pod..."
read -r

# Step 5: Inspect userns pod
echo "=========================================="
echo "POD WITH USER NAMESPACES (hostUsers: false)"
echo "=========================================="
echo ""
echo ">>> Inside the container:"
kubectl exec -n userns-demo with-userns -- sh -c '
  echo "id:"; id
  echo; echo "/proc/self/uid_map:"; cat /proc/self/uid_map
  echo; echo "/proc/self/gid_map:"; cat /proc/self/gid_map
'
echo ""

echo ">>> On the host node (kubectl debug node/):"
NODE=$(kubectl get pod with-userns -n userns-demo -o jsonpath='{.spec.nodeName}')
echo ">>> Node: $NODE"
echo ">>> Look for the process -- it runs as a HIGH UID (e.g. 100999) on the host!"
echo ""
kubectl debug node/"$NODE" -it --image=busybox:1.36 -- chroot /host sh -c '
  echo "Processes matching with-userns:"
  ps aux | grep "sleep 3600" | grep -v grep | head -3
'
echo ""
echo ">>> Container root is mapped to a non-privileged UID on the host."
echo ">>> Even a container escape = zero host privileges!"
echo ""

echo "=========================================="
echo "DONE! User Namespaces = root isolation for free."
echo "=========================================="

# Cleanup
echo ""
echo ">>> Press ENTER to clean up..."
read -r
kubectl delete ns userns-demo

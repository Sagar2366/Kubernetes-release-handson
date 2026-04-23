#!/bin/bash
# Demo: HPA Scale-to-Zero (Alpha feature gate in 1.36)
# End-to-end: deploy -> load -> scale up -> stop load -> scale to ZERO
# Prerequisites: Run 00-kind-cluster/create-cluster.sh first (includes metrics-server)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "DEMO: HPA Scale to Zero"
echo "Kubernetes 1.36 - HPAScaleToZero feature gate"
echo "=========================================="
echo ""

# Step 1: Deploy workload + service
echo ">>> Deploying hpa-demo (Deployment + Service)..."
kubectl apply -f "$SCRIPT_DIR/deploy.yaml"
kubectl rollout status deploy/hpa-demo
echo ""

# Step 2: Create HPA with minReplicas: 0
echo ">>> Creating HPA with minReplicas: 0..."
kubectl apply -f "$SCRIPT_DIR/hpa.yaml"
echo ""

echo ">>> Current state:"
kubectl get hpa hpa-demo
kubectl get deploy hpa-demo
echo ""

# Pause for camera
echo ">>> Press ENTER to generate load (curl loop)..."
read -r

# Step 3: Generate load
echo ">>> Starting port-forward..."
kubectl port-forward svc/hpa-demo 8080:80 &
PF_PID=$!
sleep 2

echo ">>> Generating load in background (curl loop)..."
echo ">>> Open a second terminal and run:"
echo ">>>   watch -n5 'kubectl get hpa hpa-demo; kubectl get deploy hpa-demo; kubectl get pods -l app=hpa-demo'"
echo ""

# Run load in background
(while true; do curl -s http://localhost:8080 > /dev/null 2>&1; done) &
LOAD_PID=$!

echo ">>> Load running (PID: $LOAD_PID). Watch HPA scale UP."
echo ""

# Pause for camera -- let HPA scale up
echo ">>> Press ENTER when you've shown the scale-up (2-3 minutes)..."
read -r

# Step 4: Stop load
echo ">>> Stopping load..."
kill $LOAD_PID 2>/dev/null || true
kill $PF_PID 2>/dev/null || true
echo ""

echo ">>> Load stopped. Now watch HPA scale DOWN to 0."
echo ">>> This takes a few minutes (HPA cooldown period)."
echo ""
echo ">>> Watch with:"
echo ">>>   watch -n5 'kubectl get hpa hpa-demo; kubectl get deploy hpa-demo; kubectl get pods -l app=hpa-demo'"
echo ""

# Pause for camera -- let HPA scale to zero
echo ">>> Press ENTER when replicas reach 0..."
read -r

echo ">>> Final state:"
kubectl get hpa hpa-demo
kubectl get deploy hpa-demo
kubectl get pods -l app=hpa-demo
echo ""

echo "=========================================="
echo "DONE! HPA scaled from 1 -> N -> 0."
echo "minReplicas: 0 -- impossible before 1.36."
echo "=========================================="

# Cleanup
echo ""
echo ">>> Press ENTER to clean up..."
read -r
kubectl delete -f "$SCRIPT_DIR/hpa.yaml"
kubectl delete -f "$SCRIPT_DIR/deploy.yaml"

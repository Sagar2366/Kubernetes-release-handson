#!/bin/bash
# Demo: In-Place Pod Vertical Scaling (Beta in 1.36)
# Proves container ID stays the same after resize = no restart
# Prerequisites: Run 00-kind-cluster/create-cluster.sh first
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "DEMO: In-Place Pod Vertical Scaling"
echo "Kubernetes 1.36 - Beta (enabled by default)"
echo "=========================================="
echo ""

# Step 1: Deploy
echo ">>> Deploying nginx with CPU=200m, Memory=128Mi limits..."
kubectl apply -f "$SCRIPT_DIR/deploy.yaml"
kubectl rollout status deploy/resize-demo
echo ""

# Step 2: Capture container ID BEFORE resize
POD=$(kubectl get pod -l app=resize-demo -o jsonpath='{.items[0].metadata.name}')
CID_BEFORE=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].containerID}')
echo ">>> Pod name: $POD"
echo ">>> Container ID BEFORE resize: $CID_BEFORE"
echo ""

echo ">>> Current resources:"
kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].resources}' | jq .
echo ""

# Pause for camera
echo ">>> Press ENTER to resize IN-PLACE (no restart)..."
read -r

# Step 3: Patch resources in-place
echo ">>> Patching: CPU 200m->300m, Memory 128Mi->256Mi..."
kubectl patch pod "$POD" --subresource resize --type='merge' -p '{
  "spec": {
    "containers": [
      {
        "name": "app",
        "resources": {
          "limits": {
            "cpu": "300m",
            "memory": "256Mi"
          },
          "requests": {
            "cpu": "150m",
            "memory": "128Mi"
          }
        }
      }
    ]
  }
}'
echo ""

# Step 4: Verify -- container ID should be the SAME
echo ">>> New resources:"
kubectl get pod "$POD" -o jsonpath='{.spec.containers[0].resources}' | jq .
echo ""

CID_AFTER=$(kubectl get pod "$POD" -o jsonpath='{.status.containerStatuses[0].containerID}')
echo ">>> Container ID BEFORE: $CID_BEFORE"
echo ">>> Container ID AFTER:  $CID_AFTER"
echo ""

if [ "$CID_BEFORE" = "$CID_AFTER" ]; then
  echo ">>> SAME container ID = NO RESTART. In-place resize worked!"
else
  echo ">>> Container ID changed = container was restarted."
fi
echo ""

echo ">>> Pod status:"
kubectl get pod "$POD"
echo ""

echo "=========================================="
echo "DONE! Resources changed, container untouched."
echo "=========================================="

# Cleanup
echo ""
echo ">>> Press ENTER to clean up..."
read -r
kubectl delete -f "$SCRIPT_DIR/deploy.yaml"

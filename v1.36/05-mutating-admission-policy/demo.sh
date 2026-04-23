#!/bin/bash
# Demo: MutatingAdmissionPolicy (GA in 1.36)
# Shows CEL-based label injection without any webhook server
# Prerequisites: Run 00-kind-cluster/create-cluster.sh first
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "DEMO: MutatingAdmissionPolicy"
echo "Kubernetes 1.36 - GA (Stable)"
echo "=========================================="
echo ""

# Step 1: Show the policy
echo ">>> The policy (injects 'env: dev' on resources with 'mutator: policy' label):"
echo ""
cat "$SCRIPT_DIR/policy-add-label.yaml"
echo ""

# Pause for camera
echo ">>> Press ENTER to apply the policy..."
read -r

# Step 2: Apply policy
echo ">>> Applying MutatingAdmissionPolicy..."
kubectl apply -f "$SCRIPT_DIR/policy-add-label.yaml"
echo ""
echo ">>> Policy active! No webhook, no TLS, no extra deployment."
echo ""

# Pause for camera
echo ">>> Press ENTER to create a test pod..."
read -r

# Step 3: Show and apply test pod
echo ">>> Test pod manifest (has 'mutator: policy' label, NO 'env' label):"
cat "$SCRIPT_DIR/test-pod.yaml"
echo ""

echo ">>> Applying test pod..."
kubectl apply -f "$SCRIPT_DIR/test-pod.yaml"
echo ""

# Step 4: Verify
echo ">>> Pod labels after creation:"
kubectl get pod policy-no-env -o jsonpath='{.metadata.labels}' | jq .
echo ""

echo "=========================================="
echo "The 'env: dev' label was INJECTED by the policy."
echo "It was NOT in the original manifest."
echo ""
echo "WHAT THIS REPLACED:"
echo "  - Webhook server binary       --> 0 lines of code"
echo "  - Deployment + Service YAML    --> 0 manifests"
echo "  - TLS certificates             --> 0 certs"
echo "  - Availability monitoring      --> built-in"
echo "=========================================="

# Cleanup
echo ""
echo ">>> Press ENTER to clean up..."
read -r
kubectl delete -f "$SCRIPT_DIR/test-pod.yaml"
kubectl delete -f "$SCRIPT_DIR/policy-add-label.yaml"

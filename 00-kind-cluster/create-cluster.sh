#!/bin/bash
# Create a single kind cluster for ALL Kubernetes 1.36 demos
# Includes: metrics-server (needed for HPA demo)
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "Creating Kubernetes 1.36 kind cluster"
echo "=========================================="
echo ""

# Step 1: Create cluster
echo ">>> Creating kind cluster..."
kind create cluster --name k136-demo --config "$SCRIPT_DIR/kind-config.yaml"
echo ""

# Step 2: Verify
echo ">>> Verifying cluster..."
kubectl version
kubectl get nodes
echo ""

# Step 3: Install metrics-server (required for HPA scale-to-zero demo)
# Docs: https://github.com/kubernetes-sigs/metrics-server
echo ">>> Installing metrics-server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Kind uses self-signed certs, so patch metrics-server to skip TLS verification
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

echo ""
echo ">>> Waiting for metrics-server to be ready..."
kubectl wait --for=condition=Available deployment/metrics-server -n kube-system --timeout=120s
echo ""

echo ">>> Verifying metrics API..."
kubectl top nodes 2>/dev/null && echo "Metrics working!" || echo "Metrics still warming up -- wait 30s and try 'kubectl top nodes' again"
echo ""

echo "=========================================="
echo "Cluster 'k136-demo' is ready for all demos."
echo ""
echo "Features available:"
echo "  - User Namespaces (GA)"
echo "  - OCI VolumeSource (GA)"
echo "  - MutatingAdmissionPolicy (GA)"
echo "  - In-Place Pod Resize (Beta, enabled by default)"
echo "  - HPA Scale-to-Zero (feature gate enabled)"
echo "=========================================="

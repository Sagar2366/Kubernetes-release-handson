#!/bin/bash
# Demo: OCI VolumeSource / ImageVolume (GA in 1.36)
# Mount an OCI artifact as a read-only volume and inspect its contents
# Prerequisites: Run 00-kind-cluster/create-cluster.sh first
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "DEMO: OCI VolumeSource (ImageVolume)"
echo "Kubernetes 1.36 - GA (Stable)"
echo "=========================================="
echo ""

# Step 1: Show the YAML
echo ">>> The manifest:"
cat "$SCRIPT_DIR/pod-oci-volume.yaml"
echo ""

# Pause for camera
echo ">>> Press ENTER to deploy..."
read -r

# Step 2: Deploy
echo ">>> Deploying pod with OCI artifact mounted as volume..."
kubectl apply -f "$SCRIPT_DIR/pod-oci-volume.yaml"
echo ""

echo ">>> Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/image-volume --timeout=120s
echo ""

# Step 3: Inspect the mounted volume
echo ">>> What's inside the OCI volume at /volume?"
kubectl exec image-volume -- sh -c 'ls -R /volume; echo; cat /volume/* || true'
echo ""

echo "=========================================="
echo "KEY POINT: The OCI image (quay.io/crio/artifact:v2) is mounted"
echo "as a read-only volume, completely independent of the app image."
echo ""
echo "USE CASES:"
echo "  - ML models: mount model weights as OCI artifact"
echo "  - Config bundles: version configs as OCI images"
echo "  - Static assets: ship website content separately"
echo "  - Plugins/extensions: mount plugin JARs/binaries"
echo "  - Datasets: distribute test/reference data"
echo ""
echo "REPLACES:"
echo "  - initContainers + wget + emptyDir hacks"
echo "  - Bloated app images with bundled data"
echo "  - ConfigMaps for large config files (1MB limit)"
echo "=========================================="

# Cleanup
echo ""
echo ">>> Press ENTER to clean up..."
read -r
kubectl delete -f "$SCRIPT_DIR/pod-oci-volume.yaml"

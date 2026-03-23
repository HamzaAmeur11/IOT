#!/bin/bash
# GitOps test: change image tag in GitHub repo, verify ArgoCD auto-deploys v2.
# Run from inside the VM after the cluster is fully set up.
#
# Usage: ./scripts/test_gitops.sh

set -e

export KUBECONFIG=/home/vagrant/.kube/config

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOCKER_USER="hdameur12"
MANIFEST_REPO="https://github.com/HamzaAmeur11/Hameur-iot-manifests.git"
MANIFEST_DIR="/tmp/iot-manifests-gitops-test"
NAMESPACE="dev"

print_step() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
ok()         { echo -e "${GREEN}✓ $1${NC}"; }
fail()       { echo -e "${RED}✗ $1${NC}"; exit 1; }
info()       { echo -e "${YELLOW}→ $1${NC}"; }

# ── Step 1: Verify v1 is currently running ─────────────────────────────────
print_step "Step 1: Verify v1 is running"
RESPONSE=$(curl -s http://localhost:8888/)
echo "Response: $RESPONSE"
echo "$RESPONSE" | grep -q '"version":"v1"' || fail "Expected v1 to be running"
ok "v1 is running"

# ── Step 2: Clone the manifests repo and update to v2 ─────────────────────
print_step "Step 2: Update deployment.yaml to v2 in GitHub"
rm -rf "$MANIFEST_DIR"
git clone "$MANIFEST_REPO" "$MANIFEST_DIR"
cd "$MANIFEST_DIR"

info "Current image tag:"
grep "image:" deployment.yaml

sed -i "s|${DOCKER_USER}/iot-app:v1|${DOCKER_USER}/iot-app:v2|g" deployment.yaml

grep -q "${DOCKER_USER}/iot-app:v2" deployment.yaml || fail "Failed to update deployment.yaml"
ok "deployment.yaml updated to v2"

info "Pushing to GitHub..."
git add deployment.yaml
git commit -m "Update app to v2"
git push origin main
ok "Changes pushed to GitHub"

cd - > /dev/null

# ── Step 3: Wait for ArgoCD to detect and sync ────────────────────────────
print_step "Step 3: Waiting for ArgoCD to sync (up to 3 min)"
for i in $(seq 1 18); do
    STATUS=$(kubectl get application playground-app -n argocd \
        -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    HEALTH=$(kubectl get application playground-app -n argocd \
        -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    info "[$i/18] Sync: $STATUS | Health: $HEALTH"
    if [ "$STATUS" = "Synced" ] && [ "$HEALTH" = "Healthy" ]; then
        ok "ArgoCD synced successfully"
        break
    fi
    sleep 10
done

# ── Step 4: Wait for new pod to be ready ──────────────────────────────────
print_step "Step 4: Waiting for pod with v2 image"
kubectl wait --for=condition=ready pod -l app=playground -n "$NAMESPACE" --timeout=120s
ok "Pod is ready"

# ── Step 5: Verify v2 is now running ──────────────────────────────────────
print_step "Step 5: Verify v2 is now running"
sleep 3
RESPONSE=$(curl -s http://localhost:8888/)
echo "Response: $RESPONSE"
echo "$RESPONSE" | grep -q '"version":"v2"' || fail "Expected v2 but got: $RESPONSE"
ok "v2 is running!"

# ── Final summary ─────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  GitOps test passed! v1 → v2 successful  ${NC}"
echo -e "${GREEN}============================================${NC}"
kubectl get pods -n "$NAMESPACE"

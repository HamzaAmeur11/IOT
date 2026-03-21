#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME="hdameur12"
DOCKER_REGISTRY="${DOCKER_USERNAME}/iot-app"
GITHUB_MANIFEST_REPO="https://github.com/HamzaAmeur11/Hameur-iot-manifests.git"
GITHUB_APP_REPO="https://github.com/HamzaAmeur11/iot-app.git"
MANIFEST_LOCAL_PATH="/tmp/iot-manifests-test"
APP_LOCAL_PATH="/tmp/iot-app-test"
NAMESPACE="dev"
POD_LABEL="app=playground"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Step 1: Build and push v2 image
build_and_push_v2() {
    print_header "Step 1: Building and Pushing v2 to Docker Hub"
    
    print_info "Cloning app repository..."
    rm -rf "$APP_LOCAL_PATH"
    git clone "$GITHUB_APP_REPO" "$APP_LOCAL_PATH" || {
        print_error "Failed to clone app repo"
        return 1
    }
    
    cd "$APP_LOCAL_PATH"
    
    print_info "Building Docker image v2..."
    docker build -t "${DOCKER_REGISTRY}:v2" . || {
        print_error "Docker build failed"
        return 1
    }
    print_success "Docker image built"
    
    print_info "Pushing to Docker Hub..."
    docker push "${DOCKER_REGISTRY}:v2" || {
        print_error "Docker push failed"
        return 1
    }
    print_success "v2 image pushed to Docker Hub"
    
    cd - > /dev/null
    return 0
}

# Step 2: Update manifests repo with v2
update_manifests_v2() {
    print_header "Step 2: Updating Manifests to v2"
    
    print_info "Cloning manifests repository..."
    rm -rf "$MANIFEST_LOCAL_PATH"
    git clone "$GITHUB_MANIFEST_REPO" "$MANIFEST_LOCAL_PATH" || {
        print_error "Failed to clone manifests repo"
        return 1
    }
    
    cd "$MANIFEST_LOCAL_PATH"
    
    print_info "Updating deployment.yaml..."
    # Replace v1 with v2 in deployment.yaml
    sed -i "s|${DOCKER_REGISTRY}:v1|${DOCKER_REGISTRY}:v2|g" deployment.yaml
    
    # Verify the change
    if grep -q "${DOCKER_REGISTRY}:v2" deployment.yaml; then
        print_success "deployment.yaml updated to v2"
    else
        print_error "Failed to update deployment.yaml"
        return 1
    fi
    
    print_info "Pushing changes to GitHub..."
    git add deployment.yaml
    git commit -m "Automated test: Update app version to v2" || {
        print_error "Git commit failed"
        return 1
    }
    git push origin main || {
        print_error "Git push failed"
        return 1
    }
    print_success "v2 changes pushed to GitHub"
    
    cd - > /dev/null
    return 0
}

# Step 3: Test v1 (before)
test_v1() {
    print_header "Step 3: Testing v1 (Before)"
    
    print_info "Checking pod status..."
    kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" || return 1
    
    print_info "Testing endpoint..."
    RESPONSE=$(curl -s http://localhost:8888/)
    echo "Response: $RESPONSE"
    
    if echo "$RESPONSE" | grep -q '"version":"v1"'; then
        print_success "v1 is running"
        return 0
    else
        print_error "v1 endpoint not responding correctly"
        return 1
    fi
}

# Step 4: Trigger ArgoCD sync
trigger_argocd_sync() {
    print_header "Step 4: Triggering ArgoCD Sync"
    
    print_info "Checking for ArgoCD application..."
    kubectl get application -n argocd || {
        print_error "ArgoCD application not found"
        print_info "Creating ArgoCD application..."
        kubectl apply -f /vagrant/confs/argocd-app.yaml || {
            print_error "Failed to create ArgoCD application"
            return 1
        }
    }
    
    print_info "Waiting for ArgoCD to detect changes (30 seconds)..."
    sleep 30
    
    print_info "Checking ArgoCD app status..."
    kubectl get application -n argocd -o wide
    
    return 0
}

# Step 5: Wait for pod restart
wait_for_pod_restart() {
    print_header "Step 5: Waiting for Pod Restart"
    
    print_info "Old pod:"
    OLD_POD=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}')
    echo "  $OLD_POD"
    
    print_info "Waiting for new pod deployment (60 seconds)..."
    for i in {1..60}; do
        NEW_POD=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}')
        
        if [ "$NEW_POD" != "$OLD_POD" ]; then
            print_success "New pod detected: $NEW_POD"
            break
        fi
        
        # Check pod status
        POD_STATUS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].status.phase}')
        echo "  [$i/60] Current pod: $NEW_POD (Status: $POD_STATUS)"
        sleep 1
    done
    
    print_info "Waiting for pod to be ready..."
    kubectl wait --for=condition=ready pod -l "$POD_LABEL" -n "$NAMESPACE" --timeout=60s || {
        print_error "Pod failed to become ready"
        return 1
    }
    print_success "Pod is ready"
    
    return 0
}

# Step 6: Test v2 (after)
test_v2() {
    print_header "Step 6: Testing v2 (After)"
    
    print_info "Waiting 5 seconds for app to stabilize..."
    sleep 5
    
    print_info "Testing endpoint..."
    RESPONSE=$(curl -s http://localhost:8888/)
    echo "Response: $RESPONSE"
    
    if echo "$RESPONSE" | grep -q '"version":"v2"'; then
        print_success "v2 is running - GitOps workflow successful!"
        return 0
    else
        print_error "v2 endpoint not responding correctly"
        print_error "Pod image: $(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].spec.containers[0].image}')"
        return 1
    fi
}

# Step 7: Health check
health_check() {
    print_header "Step 7: Final Health Check"
    
    print_info "Pod status:"
    kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o wide
    
    print_info "Service status:"
    kubectl get svc -n "$NAMESPACE"
    
    print_info "Ingress status:"
    kubectl get ingress -n "$NAMESPACE"
    
    print_info "Testing health endpoint..."
    HEALTH=$(curl -s http://localhost:8888/health)
    echo "Health: $HEALTH"
    
    if echo "$HEALTH" | grep -q '"status":"healthy"'; then
        print_success "Application is healthy"
        return 0
    else
        print_error "Health check failed"
        return 1
    fi
}

# Main execution
main() {
    print_header "IoT P3 - Automated GitOps Test v1 → v2"
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker not found"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        print_error "git not found"
        exit 1
    fi
    
    print_success "All prerequisites met"
    
    # Run tests
    test_v1 || exit 1
    
    build_and_push_v2 || exit 1
    
    update_manifests_v2 || exit 1
    
    trigger_argocd_sync || exit 1
    
    wait_for_pod_restart || exit 1
    
    test_v2 || exit 1
    
    health_check || exit 1
    
    print_header "✓ All Tests Passed!"
    echo -e "${GREEN}GitOps workflow test completed successfully${NC}"
    echo -e "${GREEN}Application upgraded from v1 to v2${NC}"
}

main "$@"

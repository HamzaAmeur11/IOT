#!/bin/bash

# Automated GitOps Test - v1 to v2
# Run from inside the Vagrant VM

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}P3 GitOps Test: v1 → v2 Automation${NC}"
echo -e "${BLUE}========================================${NC}"

# Configuration
DOCKER_USER="hdameur12"
DOCKER_IMAGE="${DOCKER_USER}/iot-app"
NAMESPACE="dev"

# Test 1: Check current version (v1)
echo -e "\n${YELLOW}→ Testing current version (v1)...${NC}"
CURRENT=$(curl -s http://localhost:8888/ | grep -o '"version":"[^"]*"')
echo "Current: $CURRENT"

if echo "$CURRENT" | grep -q "v1"; then
    echo -e "${GREEN}✓ v1 is running${NC}"
else
    echo -e "${RED}✗ Expected v1${NC}"
    exit 1
fi

# Test 2: Get current pod
echo -e "\n${YELLOW}→ Checking current pod...${NC}"
OLD_POD=$(kubectl get pods -n $NAMESPACE -l app=playground -o jsonpath='{.items[0].metadata.name}')
echo "Current pod: $OLD_POD"
echo "Current image: $(kubectl get pod $OLD_POD -n $NAMESPACE -o jsonpath='{.items[0].spec.containers[0].image}')"

# Test 3: Update deployment to v2
echo -e "\n${YELLOW}→ Updating deployment to v2...${NC}"
kubectl set image deployment/playground -n $NAMESPACE \
    playground=${DOCKER_IMAGE}:v2 --record

echo -e "${GREEN}✓ Deployment updated to v2${NC}"

# Test 4: Wait for new pod
echo -e "\n${YELLOW}→ Waiting for new pod to be ready (max 60s)...${NC}"
kubectl wait --for=condition=ready pod -l app=playground -n $NAMESPACE --timeout=60s

NEW_POD=$(kubectl get pods -n $NAMESPACE -l app=playground -o jsonpath='{.items[0].metadata.name}')
echo "New pod: $NEW_POD"

# Test 5: Verify version changed to v2
echo -e "\n${YELLOW}→ Verifying version changed to v2...${NC}"
sleep 3
NEW_VERSION=$(curl -s http://localhost:8888/ | grep -o '"version":"[^"]*"')
echo "New version: $NEW_VERSION"

if echo "$NEW_VERSION" | grep -q "v2"; then
    echo -e "${GREEN}✓ v2 is now running${NC}"
else
    echo -e "${RED}✗ Expected v2 but got $NEW_VERSION${NC}"
    exit 1
fi

# Test 6: Health check
echo -e "\n${YELLOW}→ Health check...${NC}"
HEALTH=$(curl -s http://localhost:8888/health)
echo "Health: $HEALTH"

if echo "$HEALTH" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Application is healthy${NC}"
else
    echo -e "${RED}✗ Health check failed${NC}"
    exit 1
fi

# Summary
echo -e "\n${BLUE}========================================${NC}"
echo -e "${GREEN}✓ Tests Passed! v1 → v2 upgrade successful${NC}"
echo -e "${BLUE}========================================${NC}"

echo -e "\n${YELLOW}Summary:${NC}"
echo "  Old pod: $OLD_POD"
echo "  New pod: $NEW_POD"
echo "  Old version: v1"
echo "  New version: v2"
echo "  Status: ✓ Healthy"

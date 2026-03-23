#!/bin/bash
# Build and push v1 and v2 images to Docker Hub.
# Run this ONCE from your local machine before running vagrant up.
#
# Usage: ./scripts/build_versions.sh <dockerhub-username>
# Example: ./scripts/build_versions.sh hdameur12

set -e

DOCKER_USERNAME="${1:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker Hub username required${NC}"
    echo "Usage: $0 <dockerhub-username>"
    exit 1
fi

WEBAPP_DIR="$(dirname "$0")/../webapp"

build_and_push() {
    local VERSION="$1"
    local MESSAGE="$2"
    echo -e "${BLUE}=== Building $DOCKER_USERNAME/iot-app:$VERSION ===${NC}"

    docker build \
        --build-arg APP_VERSION="$VERSION" \
        --build-arg APP_MESSAGE="$MESSAGE" \
        -t "$DOCKER_USERNAME/iot-app:$VERSION" \
        "$WEBAPP_DIR"

    echo -e "${BLUE}=== Pushing $DOCKER_USERNAME/iot-app:$VERSION ===${NC}"
    docker push "$DOCKER_USERNAME/iot-app:$VERSION"
    echo -e "${GREEN}✓ $VERSION pushed successfully${NC}"
}

echo "Logging in to Docker Hub..."
docker login

build_and_push "v1" "Hello from IoT App - version 1"
build_and_push "v2" "Hello from IoT App - version 2"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Both versions available on Docker Hub:${NC}"
echo "  docker pull $DOCKER_USERNAME/iot-app:v1"
echo "  docker pull $DOCKER_USERNAME/iot-app:v2"
echo -e "${GREEN}========================================${NC}"

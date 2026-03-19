#!/bin/bash
# Helper script to build and push different versions of the app to Docker Hub

# Configuration
DOCKER_USERNAME="${1:-}"
DOCKER_PASSWORD="${2:-}"
VERSION="${3:-v1}"
REGISTRY_URL="https://registry.hub.docker.com"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error handling
set -e

if [ -z "$DOCKER_USERNAME" ]; then
    echo -e "${RED}Error: Docker username not provided${NC}"
    echo "Usage: ./build_versions.sh YOUR-USERNAME [password] [version]"
    echo ""
    echo "Examples:"
    echo "  ./build_versions.sh myuser v1"
    echo "  ./build_versions.sh myuser mypass v2"
    exit 1
fi

echo -e "${BLUE}Building Docker images for IoT App${NC}"
echo "========================================"
echo "Docker Username: $DOCKER_USERNAME"
echo "Version: $VERSION"
echo "========================================"

# Change to webapp directory
cd "$(dirname "$0")/../webapp"

echo -e "${BLUE}[1/3] Building Docker image: $DOCKER_USERNAME/iot-app:$VERSION${NC}"

# Modify Dockerfile temporarily to set correct version
TEMP_DOCKERFILE=$(mktemp)
cp Dockerfile "$TEMP_DOCKERFILE"

# Update the version in Dockerfile
sed "s/ENV APP_VERSION=.*/ENV APP_VERSION=$VERSION/" Dockerfile > "$TEMP_DOCKERFILE"

# Build with temporary Dockerfile
docker build -f "$TEMP_DOCKERFILE" -t "$DOCKER_USERNAME/iot-app:$VERSION" .

# Cleanup
rm "$TEMP_DOCKERFILE"

echo -e "${GREEN}✓ Image built successfully${NC}"

# Login if password provided
if [ -n "$DOCKER_PASSWORD" ]; then
    echo -e "${BLUE}[2/3] Logging in to Docker Hub${NC}"
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
    echo -e "${GREEN}✓ Logged in successfully${NC}"
else
    echo -e "${BLUE}[2/3] Using existing Docker login${NC}"
fi

# Push to Docker Hub
echo -e "${BLUE}[3/3] Pushing image to Docker Hub${NC}"
docker push "$DOCKER_USERNAME/iot-app:$VERSION"

echo -e "${GREEN}✓ Image pushed successfully${NC}"

# Also tag as latest if this is latest version
if [ "$VERSION" = "v2" ] || [ "$VERSION" = "latest" ]; then
    echo ""
    echo -e "${BLUE}Tagging as latest${NC}"
    docker tag "$DOCKER_USERNAME/iot-app:$VERSION" "$DOCKER_USERNAME/iot-app:latest"
    docker push "$DOCKER_USERNAME/iot-app:latest"
    echo -e "${GREEN}✓ Latest tag updated${NC}"
fi

echo ""
echo -e "${GREEN}========================================"
echo "Success! Your images are now available:"
echo "========================================"
echo "Registry URL: https://hub.docker.com/r/$DOCKER_USERNAME/iot-app"
echo "Pull command: docker pull $DOCKER_USERNAME/iot-app:$VERSION"
echo -e "${NC}"

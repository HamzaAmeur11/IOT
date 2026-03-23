#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "=== [1/4] Installing Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
    usermod -aG docker vagrant
    systemctl enable docker
    systemctl start docker
    # Wait for Docker socket to be available
    for i in $(seq 1 30); do
        docker info &>/dev/null && break
        echo "Waiting for Docker... ($i/30)"
        sleep 2
    done
    echo "Docker is ready"
else
    echo "Docker already installed"
fi

echo "=== [2/4] Installing kubectl ==="
if ! command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
    echo "kubectl ${KUBECTL_VERSION} installed"
else
    echo "kubectl already installed"
fi

echo "=== [3/4] Installing k3d ==="
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "k3d installed"
else
    echo "k3d already installed"
fi

echo "=== [4/4] Installing ArgoCD CLI ==="
if ! command -v argocd &> /dev/null; then
    curl -sSL -o /usr/local/bin/argocd \
        https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
    echo "ArgoCD CLI installed"
else
    echo "ArgoCD CLI already installed"
fi

echo "=== All tools installed successfully ==="

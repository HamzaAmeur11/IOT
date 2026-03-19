#!/bin/bash
set -e

echo "=== Installing Docker ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker vagrant
    systemctl enable docker
else
    echo "Docker already installed"
fi

echo "=== Installing kubectl ==="
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    mv kubectl /usr/local/bin/
else
    echo "kubectl already installed"
fi

echo "=== Installing k3d ==="
if ! command -v k3d &> /dev/null; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d already installed"
fi

echo "=== Installing ArgoCD CLI ==="
if ! command -v argocd &> /dev/null; then
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x argocd-linux-amd64
    mv argocd-linux-amd64 /usr/local/bin/argocd
else
    echo "ArgoCD CLI already installed"
fi

echo "=== All tools installed successfully ==="

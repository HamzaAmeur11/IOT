#!/bin/bash
set -e

export KUBECONFIG=/home/vagrant/.kube/config

echo "=== Installing ArgoCD ==="

# Check if ArgoCD is already installed
if kubectl get namespace argocd &> /dev/null; then
    echo "ArgoCD namespace already exists"
    exit 0
fi

# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD (ignore CRD annotation errors - known issue with stable manifest)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml || true

# Wait for ArgoCD to be ready
echo "=== Waiting for ArgoCD to be ready ==="
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s || true

echo "=== ArgoCD installed successfully ==="

# Get ArgoCD admin password and save it
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD" > /vagrant/argocd-password.txt
chown vagrant:vagrant /vagrant/argocd-password.txt

echo "=== ArgoCD password saved to /vagrant/argocd-password.txt ==="

#!/bin/bash

# Load IPs from ips.conf
source /vagrant/ips.conf

# Load repository URL from repos.conf
source /vagrant/repos.conf

echo "========================================="
echo "Deploying Application with ArgoCD"
echo "========================================="

# Set KUBECONFIG
export KUBECONFIG=/vagrant/k3s.yaml

# Wait for ArgoCD to be ready
echo "Checking if ArgoCD is ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# For local testing, we'll apply the app manifests directly first
echo "Applying application manifests..."
kubectl apply -f /vagrant/confs/app.yaml

# Apply ArgoCD application manifest with environment variable substitution
envsubst < /vagrant/confs/argocd-app.yaml | kubectl apply -f -

echo ""
echo "========================================="
echo "Application Deployed!"
echo "========================================="
echo "Access the application at: http://$SERVER_IP:30081"
echo ""
echo "To use ArgoCD for GitOps deployment:"
echo "1. Create a Git repository with the app.yaml file"
echo "2. Update the repoURL in confs/argocd-app.yaml"
echo "3. Apply: kubectl apply -f /vagrant/confs/argocd-app.yaml"
echo "========================================="

# Display ArgoCD access info
if [ -f /vagrant/argocd-password.txt ]; then
    echo ""
    echo "ArgoCD Dashboard:"
    echo "URL: https://$SERVER_IP:30080"
    echo "Username: admin"
    echo "Password: $(cat /vagrant/argocd-password.txt)"
    echo "========================================="
fi

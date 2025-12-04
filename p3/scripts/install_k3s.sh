#!/bin/bash

echo "========================================="
echo "Installing K3s Server for Part 3"
echo "========================================="

# Install K3s Server in single-server mode
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644" sh -

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until kubectl get nodes 2>/dev/null; do
    echo "Waiting for K3s..."
    sleep 5
done

echo "K3s is ready!"

# Copy kubeconfig to shared folder for host access
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

echo "========================================="
echo "Installing ArgoCD"
echo "========================================="

# Create namespace for ArgoCD
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd

# Change ArgoCD service to NodePort for easier access
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Set NodePort to a specific port (30080)
kubectl patch svc argocd-server -n argocd --type='json' -p='[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}]'

# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# Save password to shared folder
echo "$ARGOCD_PASSWORD" > /vagrant/argocd-password.txt
chmod 644 /vagrant/argocd-password.txt

echo "========================================="
echo "ArgoCD Setup Complete!"
echo "========================================="
echo "ArgoCD UI: https://192.168.42.110:30080"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
echo "Password also saved to: /vagrant/argocd-password.txt"
echo "========================================="

# Create dev namespace for applications
kubectl create namespace dev

echo "Setup complete!"

#!/bin/bash
set -e

export KUBECONFIG=/home/vagrant/.kube/config

echo "=== Creating dev namespace ==="
kubectl create namespace dev || true

echo "=== Deploying application ==="

# Create deployment with wil42/playground image
kubectl apply -f /vagrant/confs/deployment.yaml

# Create service
kubectl apply -f /vagrant/confs/service.yaml

# Create ingress
kubectl apply -f /vagrant/confs/ingress.yaml || true

echo "=== Waiting for deployment to be ready ==="
kubectl wait --for=condition=ready pod -l app=playground -n dev --timeout=300s || true

echo "=== Application deployed successfully ==="
echo "=== Access the application at http://localhost:8888 ==="


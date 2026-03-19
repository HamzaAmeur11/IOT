#!/bin/bash

echo "========================================="
echo "Installing Helm"
echo "========================================="

# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Wait for Helm to be available
until helm version 2>/dev/null; do
    echo "Waiting for Helm..."
    sleep 2
done

echo "Helm installed successfully!"

# Load repos from repos.conf
source /vagrant/repos.conf

echo "========================================="
echo "Adding Helm Repositories"
echo "========================================="

helm repo add prometheus-community $PROMETHEUS_REPO
helm repo add grafana $GRAFANA_REPO
helm repo update

echo "Helm repositories added!"

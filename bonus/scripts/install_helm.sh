#!/bin/bash
set -e

# Each Vagrant provisioner is a fresh shell — must re-export KUBECONFIG
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "========================================="
echo "Installing Helm"
echo "========================================="

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "Helm installed: $(helm version --short)"

source /vagrant/repos.conf

echo "========================================="
echo "Adding Helm Repositories"
echo "========================================="

helm repo add prometheus-community "$PROMETHEUS_REPO"
helm repo add grafana "$GRAFANA_REPO"
helm repo update

echo "Helm repositories added!"

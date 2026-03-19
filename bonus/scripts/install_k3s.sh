#!/bin/bash

# Load IPs from ips.conf
source /vagrant/ips.conf

echo "========================================="
echo "Installing K3s Server for Bonus"
echo "========================================="

# Install K3s Server with write-kubeconfig-mode
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --write-kubeconfig-mode 644" sh -

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
until kubectl get nodes 2>/dev/null; do
    echo "Waiting for K3s..."
    sleep 5
done

# Copy kubeconfig to shared folder for host access
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

echo "K3s is ready!"

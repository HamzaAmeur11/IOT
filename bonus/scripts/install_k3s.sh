#!/bin/bash
set -e

source /vagrant/ips.conf

echo "========================================="
echo "Installing K3s Server for Bonus"
echo "========================================="

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --write-kubeconfig-mode 644" sh -

# K3s writes its kubeconfig here — set it globally via /etc/environment
# so every subsequent shell (including the next Vagrant provisioner) picks it up
echo "KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /etc/environment
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Also set for vagrant user interactive sessions
grep -q "KUBECONFIG" /home/vagrant/.bashrc || \
  echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
grep -q "alias k=" /home/vagrant/.bashrc || \
  echo "alias k=kubectl" >> /home/vagrant/.bashrc

echo "Waiting for K3s to be ready..."
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "  Waiting for K3s..."
  sleep 5
done

echo "K3s is ready!"
kubectl get nodes -o wide

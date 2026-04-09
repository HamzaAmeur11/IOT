#!/bin/bash
set -e

source /vagrant/ips.conf

echo "========================================="
echo "Installing K3s Server for Bonus"
echo "========================================="

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --write-kubeconfig-mode 644 --tls-san $SERVER_IP" sh -

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

# Copy kubeconfig to shared folder for host access
cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
chmod 644 /vagrant/k3s.yaml

# Fix kubeconfig to use SERVER_IP instead of localhost
sed -i "s|https://127.0.0.1:6443|https://$SERVER_IP:6443|g" /vagrant/k3s.yaml

mkdir -p /vagrant/output
cp /etc/rancher/k3s/k3s.yaml /vagrant/output/k3s.yaml
chmod 644 /vagrant/output/k3s.yaml
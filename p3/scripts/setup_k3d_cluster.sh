#!/bin/bash
set -e

echo "=== Creating K3d cluster ==="

# Vagrant provisioner runs as root, but k3d uses Docker.
# Make sure Docker is running.
systemctl start docker 2>/dev/null || true
for i in $(seq 1 20); do
    docker info &>/dev/null && break
    echo "Waiting for Docker... ($i/20)"
    sleep 3
done

# Check if cluster already exists
if k3d cluster list 2>/dev/null | grep -q "iot-cluster"; then
    echo "Cluster iot-cluster already exists, skipping creation"
else
    k3d cluster create iot-cluster \
        --servers 1 \
        --agents 2 \
        --port "8888:80@loadbalancer" \
        --wait
    echo "Cluster created"
fi

echo "=== Exporting kubeconfig ==="

# Export for root (used by the rest of the provisioning scripts)
mkdir -p /root/.kube
k3d kubeconfig get iot-cluster > /root/.kube/config
export KUBECONFIG=/root/.kube/config

# Export for vagrant user (used after ssh)
mkdir -p /home/vagrant/.kube
k3d kubeconfig get iot-cluster > /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Also copy to /vagrant for host access
mkdir -p /vagrant
mkdir -p /vagrant/output
cp /home/vagrant/.kube/config /vagrant/output/k3s.yaml
chmod 644 /vagrant/output/k3s.yaml

# Persist KUBECONFIG for vagrant user shell sessions
grep -q "KUBECONFIG" /home/vagrant/.bashrc || \
    echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

# Also set alias k=kubectl for convenience
grep -q "alias k=" /home/vagrant/.bashrc || \
    echo "alias k=kubectl" >> /home/vagrant/.bashrc

echo "=== Waiting for all nodes to be ready ==="
kubectl wait --for=condition=ready node --all --timeout=300s

echo "=== K3d cluster setup complete ==="
kubectl get nodes -o wide

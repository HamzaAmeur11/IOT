#!/bin/bash
set -e

echo "=== Creating K3d cluster ==="

# Check if cluster already exists
if k3d cluster list | grep -q iot-cluster; then
    echo "Cluster iot-cluster already exists"
    exit 0
fi

# Create K3d cluster with 1 server and 2 agents
k3d cluster create iot-cluster \
    --servers 1 \
    --agents 2 \
    --port 8888:80@loadbalancer \
    --wait

echo "=== Exporting kubeconfig ==="
mkdir -p /home/vagrant/.kube
k3d kubeconfig get iot-cluster > /home/vagrant/.kube/config

# Extract the port from kubeconfig and replace address with localhost
# k3d exports internal Docker network address, we need localhost
PORT=$(grep 'server:' /home/vagrant/.kube/config | grep -oP ':\K[0-9]+' | head -1)
if [ -z "$PORT" ]; then
    PORT="6443"
fi

sed -i "s|server: https://[^:]*:[0-9]*|server: https://127.0.0.1:$PORT|g" /home/vagrant/.kube/config
echo "Updated kubeconfig to use server: https://127.0.0.1:$PORT"

# Skip TLS verification since we're using localhost
sed -i 's/insecure-skip-tls-verify: false/insecure-skip-tls-verify: true/g' /home/vagrant/.kube/config

chown -R vagrant:vagrant /home/vagrant/.kube

# Add kubeconfig to .bashrc for vagrant user
echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc

# Set kubeconfig for current session
export KUBECONFIG=/home/vagrant/.kube/config

# Wait for cluster API to be accessible
echo "=== Waiting for cluster API to be accessible ==="
max_attempts=60
attempt=0
while [ $attempt -lt $max_attempts ]; do
    if kubectl cluster-info &>/dev/null; then
        echo "Cluster API is accessible!"
        break
    fi
    attempt=$((attempt + 1))
    echo "Attempt $attempt/$max_attempts: Waiting for cluster API..."
    sleep 3
done

if [ $attempt -eq $max_attempts ]; then
    echo "Warning: Cluster API not accessible after ${max_attempts} attempts"
fi

# Wait for nodes to be ready
echo "=== Waiting for nodes to be ready ==="
kubectl wait --for=condition=ready node --all --timeout=300s || true

echo "=== K3d cluster setup complete ==="

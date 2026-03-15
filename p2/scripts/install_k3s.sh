#!/bin/bash

# Load IPs from ips.conf
source /vagrant/ips.conf

# Install K3s in Server mode only
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --flannel-iface eth1 --write-kubeconfig-mode 644" sh -

# Wait for K3s to be ready
until sudo k3s kubectl get nodes 2>/dev/null; do
    echo "Waiting for K3s to be ready..."
    sleep 2
done

# Label the server node as control-plane/master
echo "Labeling server node: hameur-s"
kubectl label node hameur-s node-role.kubernetes.io/master="" --overwrite
kubectl label node hameur-s node-role.kubernetes.io/control-plane="" --overwrite

# Copy kubeconfig to shared folder
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

# Apply the application manifests automatically
sleep 5
sudo kubectl apply -f /vagrant/app1.yaml
sudo kubectl apply -f /vagrant/app2.yaml
sudo kubectl apply -f /vagrant/app3.yaml
sudo kubectl apply -f /vagrant/ingress.yaml

echo "K3s server installed and applications deployed!"

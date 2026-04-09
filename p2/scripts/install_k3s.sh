#!/bin/bash

# Load IPs from ips.conf
source /vagrant/ips.conf

# Install K3s in Server mode only
# --tls-san: Add SERVER_IP to SSL certificate so it's valid for external connections
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --flannel-iface eth1 --write-kubeconfig-mode 644 --tls-san $SERVER_IP" sh -

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
sudo mkdir -p /vagrant/output
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/output/k3s.yaml
sudo chmod 644 /vagrant/output/k3s.yaml

# Fix kubeconfig to use SERVER_IP instead of localhost
sudo sed -i "s|https://127.0.0.1:6443|https://$SERVER_IP:6443|g" /vagrant/output/k3s.yaml

# Add kubectl alias and KUBECONFIG for vagrant user
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/vagrant/k3s.yaml" >> /home/vagrant/.bashrc

# Apply the application manifests automatically
sleep 5
sudo kubectl apply -f /vagrant/app1.yaml
sudo kubectl apply -f /vagrant/app2.yaml
sudo kubectl apply -f /vagrant/app3.yaml
sudo kubectl apply -f /vagrant/ingress.yaml

echo "K3s server installed and applications deployed!"

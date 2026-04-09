#!/bin/bash

# Source IPs from /vagrant/ips.conf
source /vagrant/ips.conf

# Install K3s Server
# --node-ip: Explicitly set the IP for the node
# --flannel-iface: Interface for the flannel CNI (usually eth1 for private network in Vagrant)
# We use --write-kubeconfig-mode 644 to make it readable
# --tls-san: Add SERVER_IP to SSL certificate so it's valid for external connections
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip $SERVER_IP --flannel-iface eth1 --write-kubeconfig-mode 644 --tls-san $SERVER_IP" sh -

# Wait for token to be generated
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
    sleep 1
done

# Ensure output directory exists
mkdir -p /vagrant/output

# Copy token to shared folder so worker can access it
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/output/node-token
sudo chmod 644 /vagrant/output/node-token

# Copy kubeconfig to shared folder for host access
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/output/k3s.yaml
sudo chmod 644 /vagrant/output/k3s.yaml

# Fix kubeconfig to use SERVER_IP instead of localhost
sudo sed -i "s|https://127.0.0.1:6443|https://$SERVER_IP:6443|g" /vagrant/output/k3s.yaml

# Copy kubectl binary if exists
if [ -f /usr/local/bin/kubectl ]; then
    sudo cp /usr/local/bin/kubectl /vagrant/output/kubectl
    sudo chmod 755 /vagrant/output/kubectl
fi

# SSH Key Generation for passwordless access
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -q -N ""
        chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
fi

# Copy public key to shared folder
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/output/server_key.pub
echo "HELLO FROM SERVER"

# Label this node as master/control-plane and wait for worker to join
export KUBECONFIG=/vagrant/output/k3s.yaml

# Add kubectl alias for vagrant user
echo "alias k='kubectl'" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/vagrant/output/k3s.yaml" >> /home/vagrant/.bashrc

# Wait for kubectl to be ready (K3s API server must be ready)
echo "Waiting for K3s API server to be ready..."
WAIT_COUNT=0
while ! kubectl get nodes &>/dev/null && [ $WAIT_COUNT -lt 30 ]; do
  echo "K3s API server not ready yet... ($WAIT_COUNT/30)"
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 1))
done

if ! kubectl get nodes &>/dev/null; then
  echo "ERROR: K3s API server failed to become ready"
  exit 1
fi

# Label the server node as control-plane/master
echo "Labeling server node: hameur-s"
kubectl label node hameur-s node-role.kubernetes.io/master="" --overwrite
kubectl label node hameur-s node-role.kubernetes.io/control-plane="" --overwrite
echo "Labeled server node: hameur-s"

# Add kubectl alias for convenience (on host machine, add to ~/.bashrc or ~/.zshrc)
echo "Setup complete! To use kubectl on your host machine:"
echo "  1. Install kubectl: curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl"
echo "  2. Export kubeconfig: export KUBECONFIG=$(pwd)/k3s.yaml"
echo "  3. Add alias: echo \"alias k='kubectl'\" >> ~/.bashrc && source ~/.bashrc"

#!/bin/bash

# Install K3s Server
# --node-ip: Explicitly set the IP for the node
# --flannel-iface: Interface for the flannel CNI (usually eth1 for private network in Vagrant)
# We use --write-kubeconfig-mode 644 to make it readable
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip 192.168.42.110 --flannel-iface eth1 --write-kubeconfig-mode 644" sh -

# Wait for token to be generated
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
    sleep 1
done

# Copy token to shared folder so worker can access it
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
sudo chmod 644 /vagrant/node-token

# Copy kubeconfig to shared folder for host access
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml
sudo chmod 644 /vagrant/k3s.yaml

# SSH Key Generation for passwordless access
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -q -N ""
    chown vagrant:vagrant /home/vagrant/.ssh/id_rsa*
fi

# Copy public key to shared folder
cp /home/vagrant/.ssh/id_rsa.pub /vagrant/server_key.pub
echo "HELLO FROM SERVER"

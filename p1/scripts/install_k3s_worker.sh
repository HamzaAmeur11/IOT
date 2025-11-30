#!/bin/bash

# Wait for token from server
while [ ! -f /vagrant/node-token ]; do
  echo "Waiting for node-token..."
  sleep 2
done

TOKEN=$(cat /vagrant/node-token)

# Install K3s Agent
# K3S_URL: Point to the server
# K3S_TOKEN: The token we got from the server
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.42.110:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent --node-ip 192.168.42.111 --flannel-iface eth1" sh -

# Setup SSH access from Server
# Wait for key to be available
while [ ! -f /vagrant/server_key.pub ]; do
    echo "Waiting for server_key.pub..."
    sleep 2
done

cat /vagrant/server_key.pub >> /home/vagrant/.ssh/authorized_keys
echo "HELLO FROM WORKER"
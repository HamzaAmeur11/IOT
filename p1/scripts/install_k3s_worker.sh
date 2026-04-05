#!/bin/bash

# Source IPs from /vagrant/ips.conf first
source /vagrant/ips.conf

# Wait with timeout for server files to be available
echo "Waiting for server to be ready..."
WAIT_COUNT=0
MAX_WAIT=120  # 4 minutes timeout (120 * 2 seconds)

while [ ! -f /vagrant/output/node-token ] && [ $WAIT_COUNT -lt $MAX_WAIT ]; do
  echo "Waiting for node-token... (z$WAIT_COUNT/$MAX_WAIT)"
  sleep 2
  WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ ! -f /vagrant/output/node-token ]; then
  echo "ERROR: Failed to get node-token from server after 4 minutes"
  exit 1
fi

TOKEN=$(cat /vagrant/output/node-token)
echo "Got token from server"

# Install K3s Agent
# K3S_URL: Point to the server
# K3S_TOKEN: The token we got from the server
echo "Starting K3s agent with SERVER_IP=$SERVER_IP and WORKER_IP=$WORKER_IP"
curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$TOKEN INSTALL_K3S_EXEC="agent --node-ip $WORKER_IP --flannel-iface eth1" sh -

if [ $? -ne 0 ]; then
  echo "ERROR: K3s agent installation failed"
  exit 1
fi

# Setup SSH access from Server
# Wait for key to be available
while [ ! -f /vagrant/output/server_key.pub ]; do
  echo "Waiting for server_key.pub..."
  sleep 2
done

alias k=kubectl

cat /vagrant/output/server_key.pub >> /home/vagrant/.ssh/authorized_keys
echo "HELLO FROM WORKER"
echo "Worker node joined successfully. Labels will be applied by the server node."
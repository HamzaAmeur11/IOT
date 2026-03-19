# Inception-of-Things: Part 3 - Vagrant-Based GitOps Solution

## Overview

This is a **complete Vagrant-based GitOps infrastructure** for 42 Inception-of-Things Part 3. The Vagrant VM automatically:

- Installs Docker, kubectl, k3d, and ArgoCD CLI
- Creates a K3d Kubernetes cluster with 1 server and 2 agents
- Deploys ArgoCD for GitOps management
- Deploys your application via GitOps
- Exposes the application on port 8888 (accessible from the host)

## New: Use Your Own App!

See **[GITHUB_SETUP.md](GITHUB_SETUP.md)** to:
- Push your web app to GitHub
- Use GitHub Container Registry for Docker images
- Set up GitHub Actions for automatic builds
- Deploy via ArgoCD from your manifests repo

## Quick Start

### 1. Start the Vagrant VM

```bash
cd p3
vagrant up
```

This will:
- Create and provision the VM
- Install all required tools
- Set up the K3d cluster
- Deploy ArgoCD
- Deploy the application

### 2. Access the Application

```bash
curl http://localhost:8888/
# Expected output: {"status":"ok","message":"v1"}
```

### 3. SSH into the VM (Optional)

```bash
vagrant ssh
```

Inside the VM, you can run:
```bash
kubectl get pods -A
kubectl get services -A
```

### 4. Access ArgoCD Web UI (Optional)

From inside the VM:
```bash
# Get ArgoCD password
cat /vagrant/argocd-password.txt

# Port forward (in the VM)
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Then open https://localhost:8080 in your browser from the host (port 8080 is forwarded).

## Project Structure

```
p3/
├── Vagrantfile              # Vagrant configuration
├── ips.conf                 # Network configuration
├── README.md                # This file
├── scripts/
│   ├── install_tools.sh     # Install Docker, kubectl, k3d, ArgoCD
│   ├── setup_k3d_cluster.sh # Create K3d cluster
│   ├── setup_argocd.sh      # Install ArgoCD
│   └── deploy_app.sh        # Deploy application
└── confs/
    ├── deployment.yaml      # Kubernetes Deployment
    ├── service.yaml         # Kubernetes Service
    ├── ingress.yaml         # Kubernetes Ingress
    └── argocd-app.yaml      # ArgoCD Application manifest
```

## Common Commands

### Stop the VM

```bash
vagrant halt
```

### Destroy the VM

```bash
vagrant destroy
```

### Restart the VM

```bash
vagrant reload
```

### Reprovision the VM

```bash
vagrant provision
```

### Check VM Status

```bash
vagrant status
```

## Network Configuration

- **VM IP**: 192.168.56.110 (configured in `ips.conf`)
- **Application Port**: 8888 (forwarded to host)
- **ArgoCD Port**: 8080 (forwarded to host for optional testing)
- **API Server Port**: 6443 (available if needed)

## Specifications

| Component | Value |
|-----------|-------|
| Cluster Name | `iot-cluster` |
| Cluster Servers | 1 |
| Cluster Agents | 2 |
| Application Image | `wil42/playground:latest` |
| Application Namespace | `dev` |
| Application Port | 8888 |
| ArgoCD Namespace | `argocd` |
| VM Memory | 4096 MB |
| VM CPUs | 2 |

## Troubleshooting

### Application not responding

1. Check if the VM is running:
   ```bash
   vagrant status
   ```

2. SSH into the VM and check the deployment:
   ```bash
   vagrant ssh
   kubectl get pods -n dev
   kubectl describe pod -n dev
   ```

### K3d cluster not created

1. SSH into the VM:
   ```bash
   vagrant ssh
   ```

2. Manually create the cluster:
   ```bash
   k3d cluster create iot-cluster --servers 1 --agents 2 --port 8888:80@loadbalancer
   ```

3. Export kubeconfig:
   ```bash
   k3d kubeconfig get iot-cluster > ~/.kube/config
   ```

### Kubernetes commands not working

Make sure kubeconfig is set:
```bash
vagrant ssh
export KUBECONFIG=/home/vagrant/.kube/config
kubectl get pods -a
```

## Notes

- All scripts are automatically executed during `vagrant up`
- The VM has 4GB RAM and 2 CPUs (adjust in `Vagrantfile` if needed)
- Port forwarding allows access from the host machine
- The `confs/` folder is synced with the VM, so you can edit manifests from the host

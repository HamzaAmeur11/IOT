# IoT - Part 3: K3d and Argo CD

## Prerequisites (run on your local machine before `vagrant up`)

Build and push both Docker image versions to Docker Hub:
```bash
./scripts/build_versions.sh hdameur12
```

## Setup

```bash
# 1. Start the VM (only installs base tools automatically)
vagrant up

# 2. SSH into the VM
vagrant ssh

# 3. Inside the VM: create the k3d cluster
sudo /vagrant/scripts/setup_k3d_cluster.sh

# 4. Install ArgoCD (note the printed admin password)
sudo /vagrant/scripts/setup_argocd.sh

# 5. Deploy the app via ArgoCD (GitOps - reads from GitHub)
sudo /vagrant/scripts/deploy_app.sh
```

## Access ArgoCD UI

In a separate terminal on your host machine:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: **https://localhost:8080** (username: `admin`)

## Access the Application

```bash
curl http://localhost:8888/
# Expected: {"message": "Hello from IoT App - version 1", "status": "ok", "version": "v1"}
```

## GitOps Test: Switch v1 → v2

Run inside the VM:
```bash
sudo /vagrant/scripts/test_gitops.sh
```

This script:
1. Verifies v1 is running
2. Updates `deployment.yaml` in GitHub to use `v2`
3. Waits for ArgoCD to auto-sync
4. Verifies v2 is now running

Or manually:
```bash
# In your local clone of https://github.com/HamzaAmeur11/Hameur-iot-manifests
sed -i 's/iot-app:v1/iot-app:v2/' deployment.yaml
git add deployment.yaml && git commit -m "v2" && git push
# Wait ~3 minutes, then:
curl http://localhost:8888/
# Expected: {"version": "v2", ...}
```

## Repository Structure

```
p3/
├── confs/
│   ├── argocd-app.yaml     # ArgoCD Application (points to GitHub)
│   ├── deployment.yaml     # App deployment (image tag = version)
│   ├── service.yaml        # ClusterIP service
│   └── ingress.yaml        # Traefik ingress
├── scripts/
│   ├── install_tools.sh    # Docker, kubectl, k3d, argocd CLI
│   ├── setup_k3d_cluster.sh
│   ├── setup_argocd.sh
│   ├── deploy_app.sh       # Applies argocd-app.yaml only
│   ├── build_versions.sh   # Build & push v1+v2 to Docker Hub
│   └── test_gitops.sh      # Automated v1→v2 GitOps test
├── webapp/
│   ├── app.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .github/workflows/build.yml
├── Vagrantfile
├── ips.conf
└── .gitignore
```

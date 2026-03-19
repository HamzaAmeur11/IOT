# P3 Implementation Checklist - Step-by-Step Execution Guide

## Overview

Your project is mostly ready! This checklist guides you through the actual execution. You have:
- ✅ Vagrant VM setup
- ✅ Installation scripts for Docker, k3d, ArgoCD
- ✅ Flask webapp with versioning
- ✅ Kubernetes manifests template

**What you need to do now:**
1. Understand the 3 concepts (K3d vs k3s vs k3c, ArgoCD, Docker Hub)
2. Set up GitHub repositories (manifests repo + optionally app repo)
3. Push app to Docker Hub with v1 & v2 tags
4. Update ArgoCD app to point to your GitHub manifests
5. Deploy and verify

---

## Phase 1: Learning & Understanding

### Task 1.1: Watch Video (20 min)
- Video: Rancher Meetup - May 2020 about K3s/K3c/K3d
- Link: https://www.youtube.com/watch?v=hMr3prm9gDM&ab_channel=Rancher
- Key takeaways:
  - K3s = lightweight Kubernetes binary
  - K3d = K3s running in Docker containers  
  - K3c = alternative containerization approach
  - ArgoCD = GitOps continuous deployment

### Task 1.2: Read ArgoCD Basics (15 min)
- Link: https://argo-cd.readthedocs.io/en/stable/understand_the_basics/
- Key concepts:
  - Single source of truth = GitHub repo
  - Auto-sync = automatic deployment on repo change
  - Declarative = define desired state in YAML

### Task 1.3: Understand Docker Hub Role (5 min)
- Public image registry (like npm, pypi for containers)
- Tags = versioning (v1, v2, latest)
- CI/CD integration = auto-build on push
- In this project: store app images with v1 & v2 tags

---

## Phase 2: Prepare GitHub Repositories

### Task 2.1: Create GitHub Repository for Manifests

**For public repo (REQUIRED):**

1. Go to https://github.com/new
2. Create repo: `YOUR-USERNAME-iot-manifests`
3. Make it **PUBLIC**
4. Do NOT initialize with README (we'll add files manually)

**Clone and add manifests locally:**

```bash
# Clone your new repo
git clone https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git
cd YOUR-USERNAME-iot-manifests

# Copy existing manifests from p3
cp /path/to/IOT/p3/confs/deployment.yaml .
cp /path/to/IOT/p3/confs/service.yaml .
cp /path/to/IOT/p3/confs/ingress.yaml .

# Edit deployment.yaml for YOUR app image
# Change this line:
# image: wil42/playground:latest
# To:
# image: YOUR-DOCKERHUB-USERNAME/iot-app:v1

# Create README
cat > README.md << 'EOF'
# IoT App - Kubernetes Manifests

This repository contains Kubernetes manifests for the IoT application.
It's used by ArgoCD for continuous deployment (GitOps).

## Files

- `deployment.yaml` - Application deployment
- `service.yaml` - Kubernetes service
- `ingress.yaml` - Ingress configuration

## GitOps Workflow

Push changes to this repo → ArgoCD automatically deploys changes to cluster.
EOF

# Commit and push
git add .
git commit -m "Initial commit: Add Kubernetes manifests"
git push -u origin main

# Save repo URL for later
echo "Your manifests repo: https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests"
```

### Task 2.2 (Optional): Create GitHub Repository for App Code

If you want to set up CI/CD with GitHub Actions to auto-build images:

```bash
# On GitHub: Create repo https://github.com/YOUR-USERNAME/iot-app

# Clone locally
git clone https://github.com/YOUR-USERNAME/iot-app.git
cd iot-app

# Copy app files
cp /path/to/IOT/p3/webapp/* .

# Create GitHub Actions workflow for automatic Docker builds
mkdir -p .github/workflows
cat > .github/workflows/build.yml << 'EOF'
name: Build and Push Docker Image

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: docker build -t ${{ secrets.DOCKER_USERNAME }}/iot-app:latest .
    
    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Push to Docker Hub
      run: docker push ${{ secrets.DOCKER_USERNAME }}/iot-app:latest
EOF

git add .
git commit -m "Initial commit: Flask app + GitHub Actions CI/CD"
git push -u origin main
```

---

## Phase 3: Docker Hub Setup

### Task 3.1: Create Docker Hub Account

1. Go to https://hub.docker.com
2. Sign up (or login if you have account)
3. Note your username for later

### Task 3.2: Build and Push Images to Docker Hub

```bash
# Navigate to webapp
cd /path/to/IOT/p3/webapp

# Login to Docker Hub
docker login
# Enter username and password

# Build v1
docker build -t YOUR-DOCKERHUB-USERNAME/iot-app:v1 .

# Push v1
docker push YOUR-DOCKERHUB-USERNAME/iot-app:v1

# Verify it's public (go to: https://hub.docker.com/r/YOUR-USERNAME/iot-app)
```

### Task 3.3: Build and Push v2

Modify the app for v2:

```bash
# Edit app.py to show v2
sed -i "s/APP_VERSION=v1/APP_VERSION=v2/" webapp/Dockerfile

# Rebuild and push
docker build -t YOUR-DOCKERHUB-USERNAME/iot-app:v2 .
docker push YOUR-DOCKERHUB-USERNAME/iot-app:v2

# Tag v2 as latest (optional)
docker tag YOUR-DOCKERHUB-USERNAME/iot-app:v2 YOUR-DOCKERHUB-USERNAME/iot-app:latest
docker push YOUR-DOCKERHUB-USERNAME/iot-app:latest
```

**Verify on Docker Hub:**
- Go to: https://hub.docker.com/r/YOUR-USERNAME/iot-app/tags
- You should see: v1, v2, latest

---

## Phase 4: Deploy Everything

### Task 4.1: Update ArgoCD Application Manifest

Edit `/path/to/IOT/p3/confs/argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: iot-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Task 4.2: Start the VM

```bash
cd /path/to/IOT/p3
vagrant up

# This will:
# 1. Create VM
# 2. Install Docker, k3d, ArgoCD CLI
# 3. Create k3d cluster
# 4. Install ArgoCD
# 5. Deploy initial playground app
```

### Task 4.3: Setup ArgoCD

```bash
# SSH into VM
vagrant ssh

# Create dev namespace
kubectl create namespace dev

# Apply ArgoCD application
kubectl apply -f /vagrant/confs/argocd-app.yaml

# Verify
kubectl get applications -n argocd
kubectl get pods -n dev
```

### Task 4.4: Verify Deployment

```bash
# Check pods are running
kubectl get pods -n dev
# Should see: iot-app pod in Running state

# Test application (from host machine)
curl http://localhost:8888/
# Expected: {"status":"ok","message":"...","version":"v1"}

# Check ArgoCD sync status
argocd app get iot-app
# Should show: Synced
```

---

## Phase 5: Test GitOps Workflow (Version Change)

### Task 5.1: Update Manifests to v2

```bash
# In your manifests repo
cd /path/to/YOUR-USERNAME-iot-manifests

# Edit deployment.yaml
# Change: image: YOUR-DOCKERHUB-USERNAME/iot-app:v1
# To:     image: YOUR-DOCKERHUB-USERNAME/iot-app:v2

git add deployment.yaml
git commit -m "Change app version to v2"
git push

# ArgoCD will detect within <1 minute and auto-sync!
```

### Task 5.2: Verify ArgoCD Synced

```bash
# Watch deployment update
kubectl get pods -n dev -w
# Pod should restart with v2 image

# Check ArgoCD dashboard
# From host: ssh into VM, then:
kubectl port-forward -n argocd svc/argocd-server 8080:443
# Access: https://localhost:8080
# Login: admin / (check password with: cat /vagrant/argocd-password.txt)
# See sync status

# Test v2 endpoint
curl http://localhost:8888/
# Expected: {"status":"ok","message":"...","version":"v2"}
```

---

## Phase 6: Take Screenshots/Verification

### Required Verification Screenshots

1. **Kubernetes namespaces:**
   ```bash
   kubectl get ns
   ```
   Expected output should show `argocd` and `dev`

2. **Pods in dev namespace:**
   ```bash
   kubectl get pods -n dev
   ```
   Expected: Pod with your app running

3. **ArgoCD Application:**
   ```bash
   argocd app get iot-app
   ```
   Expected: Shows "Synced" status

4. **ArgoCD Dashboard:**
   - Port forward to 8080
   - Screenshot showing app as "Synced"
   - Show the deployment details

5. **Application Test v1 → v2:**
   - curl v1 response
   - Update GitHub repo to v2
   - curl v2 response (after sync)

---

## Common Issues & Solutions

### Issue: ArgoCD won't sync

```bash
# Check ArgoCD app status
kubectl describe app iot-app -n argocd

# Check if it can access GitHub (might need Personal Access Token for private repos)
# For public repos, no auth needed

# Force sync
argocd app sync iot-app

# Check repository is correct
argocd app get iot-app | grep repoURL
```

### Issue: Pod not starting

```bash
# Check pod logs
kubectl logs -n dev <pod-name>

# Check image exists
docker pull YOUR-DOCKERHUB-USERNAME/iot-app:v1

# Describe pod for events
kubectl describe pod -n dev <pod-name>
```

### Issue: Can't access app at localhost:8888

```bash
# Check service type
kubectl get svc -n dev

# Check port forwarding worked
kubectl port-forward svc/iot-app -n dev 8888:8888

# Test from VM
vagrant ssh
curl http://localhost:8888/
```

---

## Deliverables Checklist

- [ ] GitHub manifests repo created and public
- [ ] Docker Hub images pushed (v1 and v2 tags)
- [ ] GitHub repo has member's username in it
- [ ] ArgoCD installed and running
- [ ] Namespaces created: `argocd`, `dev`
- [ ] App deployed via ArgoCD
- [ ] ArgoCD shows "Synced" status
- [ ] Testing: v1 → v2 version change triggers auto-deploy
- [ ] Screenshots show all required output
- [ ] ArgoCD dashboard accessible and showing app

---

## Quick Reference URLs

- **Your Docker Hub images:** https://hub.docker.com/r/YOUR-USERNAME/iot-app
- **Your GitHub manifests:** https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests
- **ArgoCD Docs:** https://argo-cd.readthedocs.io/en/stable/
- **K3d GitHub:** https://github.com/k3d-io/k3d

---

## Time Estimation

- Phase 1 (Learning): ~45 minutes
- Phase 2 (GitHub setup): ~15 minutes
- Phase 3 (Docker Hub): ~20 minutes
- Phase 4 (Deployment): ~30 minutes (vagrant up takes time)
- Phase 5 (GitOps test): ~10 minutes
- Phase 6 (Verification): ~10 minutes

**Total: ~2-2.5 hours**

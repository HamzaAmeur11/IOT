# Complete Setup Guide: K3d + ArgoCD + GitOps

## Part 0: Understanding Key Concepts

### K3d vs K3s vs K3c

**K3s** - Lightweight Kubernetes distribution
- Minimal, single binary Kubernetes (~40MB)
- Perfect for edge computing and IoT
- No Docker dependency (uses containerd by default)

**K3d** - K3s in Docker
- Runs K3s nodes as Docker containers
- You need Docker to run k3d
- Great for local k8s development & testing
- Isolates K3s cluster from host machine

**K3c** - K3s in Container
- Alternative containerization of K3s
- Similar to K3d but different approach
- Less commonly used

### Argo CD (GitOps)

**GitOps Principle**: Version control is the single source of truth
- Store your infrastructure/app configs in Git
- ArgoCD watches Git repo and auto-syncs deployments
- Changes to repo automatically update cluster

**How it works**:
1. You define app configs in GitHub
2. ArgoCD monitors the repo
3. Any change to repo → automatic deployment
4. Dashboard shows sync status

### Docker Hub

**Role in this project**:
- **Image Registry**: Central place to store Docker images
- **Version Control**: Tag images (v1, v2, latest)
- **Public/Private**: Share app or keep private
- **CI/CD Integration**: Automated builds on push

**Continuous Integration** - Automated building & testing
- GitHub Actions watches your app code repo
- On push → auto builds Docker image → pushes to Docker Hub

**Continuous Deployment** - Automated deployment of built images
- ArgoCD watches manifest repo
- On change → updates K3d cluster
- Updates image tag → auto pulls new version

---

## Part 1: Installation & Setup

### Step 1.1: Verify Prerequisites

```bash
# Check if Docker is installed
docker --version

# Check if kubectl is installed
kubectl version --client

# Check if k3d is installed
k3d version
```

### Step 1.2: Install k3d (if not present)

```bash
# Method 1: Using curl
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Method 2: Using package manager (Linux)
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y k3d

# Method 3: macOS using brew
brew install k3d
```

### Step 1.3: Create K3d Cluster

```bash
# Create cluster with 1 server and 2 agents
k3d cluster create iot-cluster \
  --servers 1 \
  --agents 2 \
  --port 8080:80@loadbalancer \
  --port 8443:443@loadbalancer \
  -p 8888:8888@agent:0

# Update kubeconfig
k3d kubeconfig get iot-cluster > ~/.kube/config

# Verify cluster
kubectl get nodes
kubectl get pods -A
```

### Step 1.4: Create Kubernetes Namespaces

```bash
# Create namespaces
kubectl create namespace argocd
kubectl create namespace dev

# Verify
kubectl get ns
```

---

## Part 2: ArgoCD Installation

### Step 2.1: Install ArgoCD

```bash
# Add helm repo for ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Or use kubectl to install
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl rollout status deployment/argocd-server -n argocd
```

### Step 2.2: Access ArgoCD Dashboard

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to dashboard
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080
# Username: admin
# Password: (from above)
```

### Step 2.3: Install ArgoCD CLI (Optional)

```bash
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
argocd version
```

---

## Part 3: Application Setup

### Step 3.1: Choose Application

**Option A: Use Pre-made**
```bash
# Use wil42/playground from Docker Hub (already has v1 & v2)
# Continue to Step 3.3
```

**Option B: Create Your Own**

Go to `webapp/` directory:
```bash
ls -la
# app.py, requirements.txt, Dockerfile, docker-compose.yml
```

### Step 3.2: Build & Push Application to Docker Hub

```bash
# Login to Docker Hub
docker login

# Build v1
cd webapp
docker build -t YOUR-USERNAME/iot-app:v1 .

# Push v1
docker push YOUR-USERNAME/iot-app:v1

# For v2, modify app.py (change version output)
# Then rebuild
docker build -t YOUR-USERNAME/iot-app:v2 .
docker push YOUR-USERNAME/iot-app:v2

# Tag as latest
docker tag YOUR-USERNAME/iot-app:v2 YOUR-USERNAME/iot-app:latest
docker push YOUR-USERNAME/iot-app:latest
```

### Step 3.3: Create GitHub Repository for Manifests

**Create on GitHub.com**:
1. New repo: `YOUR-USERNAME-iot-manifests` or similar
2. Make it PUBLIC

**Add manifests**:
```bash
mkdir iot-manifests
cd iot-manifests
git init
git branch -M main

# Create deployment manifest
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: iot-app
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: iot-app
  template:
    metadata:
      labels:
        app: iot-app
    spec:
      containers:
      - name: iot-app
        image: YOUR-USERNAME/iot-app:v1
        ports:
        - containerPort: 8888
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
EOF

# Create service
cat > service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: iot-app
  namespace: dev
spec:
  type: LoadBalancer
  selector:
    app: iot-app
  ports:
  - protocol: TCP
    port: 8888
    targetPort: 8888
EOF

# Commit and push
git add .
git commit -m "Initial manifests"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git
git push -u origin main
```

---

## Part 4: ArgoCD Application Setup

### Step 4.1: Create ArgoCD Application Manifest

```bash
cat > argocd-app.yaml << 'EOF'
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
    syncOptions:
    - CreateNamespace=true
EOF
```

### Step 4.2: Deploy ArgoCD Application

```bash
# Apply argocd app
kubectl apply -f argocd-app.yaml

# Verify ArgoCD app is created
kubectl get applications -n argocd

# Check sync status
argocd app get iot-app

# Or view in web dashboard: https://localhost:8080
```

---

## Part 5: Verify Deployment

### Step 5.1: Check Deployment

```bash
# Verify pods are running
kubectl get pods -n dev
# Expected: iot-app pod running

# Check ArgoCD sync status
kubectl get applications -n argocd
# Check SYNC STATUS column

# Check service
kubectl get svc -n dev

# Test application
kubectl port-forward svc/iot-app -n dev 8888:8888
# In another terminal: curl http://localhost:8888/
```

### Step 5.2: View ArgoCD Dashboard

```bash
# Port forward (if not already done)
kubectl port-forward svc/argocd-server -n argocd 8080:443 -n argocd

# Open: https://localhost:8080
# Look for "iot-app" application
# View sync status and deployment details
```

---

## Part 6: Test GitOps - Version Update

### Step 6.1: Update to v2

```bash
# In your manifests repo
cd iot-manifests

# Edit deployment.yaml
# Change: image: YOUR-USERNAME/iot-app:v1
# To:     image: YOUR-USERNAME/iot-app:v2

git add deployment.yaml
git commit -m "Update to v2"
git push

# ArgoCD will automatically detect and sync!
```

### Step 6.2: Verify Sync

```bash
# Watch ArgoCD sync
argocd app get iot-app --refresh

# Watch kubectl
kubectl get pods -n dev -w

# Or check dashboard - app should show "Synced"
```

### Step 6.3: Test v2 Application

```bash
# Pod should have restarted with v2 image
kubectl get pods -n dev

# Test application returns v2
curl http://localhost:8888/
```

---

## Quick Troubleshooting

### ArgoCD not syncing
```bash
# Check application status
kubectl describe application iot-app -n argocd

# Check repo is accessible
argocd repo add https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git

# Force sync
argocd app sync iot-app
```

### Pods not starting
```bash
# Check pod logs
kubectl logs -n dev <pod-name>

# Describe pod
kubectl describe pod -n dev <pod-name>

# Check image is correct
kubectl get deployment -n dev -o yaml | grep image
```

### Connection issues
```bash
# Verify cluster running
k3d cluster list

# Check nodes
kubectl get nodes

# Check all resources
kubectl get all -A
```

---

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/en/stable/)
- [K3d GitHub](https://github.com/k3d-io/k3d)
- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [GitOps Guide](https://www.gitops.tech/)

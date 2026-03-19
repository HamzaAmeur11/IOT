# GitHub-Based Test Setup for p3

This guide shows how to use **GitHub Container Registry (GHCR)** and **GitHub Actions** to automatically build, push, and deploy your app.

## Setup Overview

1. Push code to GitHub
2. GitHub Actions automatically builds Docker image
3. Image pushed to GitHub Container Registry (GHCR)
4. ArgoCD pulls and deploys from your GitHub manifest repo

## Step 1: Create GitHub Repositories

### Repository 1: `iot-app` (Application Code + Docker Image)

```bash
mkdir iot-app
cd iot-app
git init
git branch -M main

# Copy the web app files
cp -r ../p3/webapp/* .

# Copy GitHub Actions workflow
mkdir -p .github/workflows
cp ../.github/workflows/build.yml .github/workflows/

# Initial commit
git add .
git commit -m "Initial commit: Flask app with CI/CD"

# Add and push to GitHub
git remote add origin https://github.com/YOUR-USERNAME/iot-app.git
git push -u origin main
```

### Repository 2: `iot-app-manifests` (Kubernetes Manifests + GitOps)

```bash
mkdir iot-app-manifests
cd iot-app-manifests
git init
git branch -M main

# Create deployment manifests
mkdir -p k8s
cat > k8s/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: playground
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: playground
  template:
    metadata:
      labels:
        app: playground
    spec:
      containers:
      - name: playground
        image: ghcr.io/YOUR-USERNAME/iot-app:latest
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

cat > k8s/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: playground
  namespace: dev
spec:
  type: ClusterIP
  selector:
    app: playground
  ports:
  - name: http
    protocol: TCP
    port: 8888
    targetPort: 8888
EOF

cat > k8s/ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: playground-ingress
  namespace: dev
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: playground
            port:
              number: 8888
EOF

# Create README
cat > README.md << 'EOF'
# IoT App - GitOps Manifests

Kubernetes manifests for IoT app deployment via ArgoCD.

## Deploy

```bash
kubectl apply -f k8s/
```
EOF

# Initial commit
git add .
git commit -m "Initial commit: K8s manifests"

# Add and push to GitHub
git remote add origin https://github.com/YOUR-USERNAME/iot-app-manifests.git
git push -u origin main
```

## Step 2: Set GitHub Secrets (If Using Private Image)

**This is optional** - GHCR can be public or private.

If you want a **private** GHCR image:

1. Go to **your app repo** → Settings → Secrets and variables → Actions
2. Create a new secret (optional, usually not needed for public repos)

If using a **public** GHCR image (recommended):
- No secrets needed - anyone can pull the image

## Step 3: Update p3 ArgoCD Configuration

Edit `p3/confs/argocd-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: playground-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR-USERNAME/iot-app-manifests.git
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Step 4: Deploy with Vagrant

```bash
cd p3
vagrant up
```

This will:
1. Create K3d cluster
2. Install ArgoCD
3. Deploy your app from your manifests repo

## How It Works

```
GitHub Repo (iot-app)
    ↓
    Push code
    ↓
GitHub Actions (build.yml)
    ↓
    Build Docker image
    ↓
GHCR (ghcr.io/YOUR-USERNAME/iot-app:latest)
    ↓
    ArgoCD checks for new image
    ↓
GitHub Manifests Repo (iot-app-manifests)
    ↓
    ArgoCD deploys from here
    ↓
K8s Cluster
```

## Testing the Complete Flow

### 1. Test GitHub Actions

Push a change to the `iot-app` repo:
```bash
cd iot-app
echo "# Updated" >> README.md
git add .
git commit -m "Update readme"
git push
```

Check the Actions tab on GitHub to see the build running.

### 2. Check GHCR Image

After the build completes:
```bash
# Check available images
curl -s https://api.github.com/users/YOUR-USERNAME/packages | jq '.[] | select(.name=="iot-app")'

# Or visit: https://github.com/YOUR-USERNAME?tab=packages
```

### 3. Test Deployment

```bash
# SSH into the VM
vagrant ssh

# Check deployment
kubectl get pods -n dev
kubectl describe deployment playground -n dev

# Check ArgoCD status
argocd app list
argocd app info playground-app
```

### 4. Test the App

```bash
curl http://localhost:8888/
# {"status":"ok","message":"Hello from IoT App - Python Flask","version":"v1"}
```

## Making Updates

1. **Update app code** in `iot-app` repo:
   ```bash
   cd iot-app
   # Edit app.py
   git add .
   git commit -m "Add new feature"
   git push
   ```

2. **GitHub Actions** automatically builds new image: `ghcr.io/YOUR-USERNAME/iot-app:latest`

3. **ArgoCD** detects the new image and redeploys (automatic)

4. **Your new version runs** on the cluster!

## GHCR Image Access

### Public Image URL
```
ghcr.io/YOUR-USERNAME/iot-app:latest
ghcr.io/YOUR-USERNAME/iot-app:SHA-HASH
```

### Pull from any machine
```bash
docker pull ghcr.io/YOUR-USERNAME/iot-app:latest
docker run -p 8888:8888 ghcr.io/YOUR-USERNAME/iot-app:latest
```

## Troubleshooting

### GitHub Actions build fails
1. Check the Actions tab on GitHub for error logs
2. Make sure Dockerfile and requirements.txt are correct
3. GHCR credentials are automatic (uses `GITHUB_TOKEN`)

### ArgoCD not syncing
```bash
kubectl describe application -n argocd playground-app
argocd app sync playground-app --force
```

### Can't pull image
- Make sure image is public or credentials are configured
- Check image name matches in deployment.yaml: `ghcr.io/YOUR-USERNAME/iot-app:latest`

## Files to Update

| File | Location | Change |
|------|----------|--------|
| Manifest repo URL | `p3/confs/argocd-app.yaml` | `repoURL: https://github.com/YOUR-USERNAME/iot-app-manifests` |
| Docker image | `k8s/deployment.yaml` | `image: ghcr.io/YOUR-USERNAME/iot-app:latest` |

## Quick Reference

| Component | Details |
|-----------|---------|
| App Image Repo | `https://github.com/YOUR-USERNAME/iot-app.git` |
| Manifests Repo | `https://github.com/YOUR-USERNAME/iot-app-manifests.git` |
| GHCR Image | `ghcr.io/YOUR-USERNAME/iot-app:latest` |
| ArgoCD Source | Manifests repo (`iot-app-manifests`) |
| CI/CD Pipeline | GitHub Actions (auto-builds on push) |

Enjoy fully automated GitOps! 🚀

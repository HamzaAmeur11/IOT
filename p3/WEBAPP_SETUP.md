# Complete Guide: Push App to GitHub and Test with p3

## Step 1: Test the Web App Locally

```bash
cd webapp

# Option 1: Using Python directly
pip install -r requirements.txt
python app.py
# Test: curl http://localhost:8888/

# Option 2: Using Docker Compose
docker-compose up
# Test: curl http://localhost:8888/
```

## Step 2: Build and Push Docker Image to Docker Hub

### Prerequisites
- Docker Hub account (https://hub.docker.com)
- Docker installed on your machine

### Push your App
```bash
# Build the Docker image
docker build -t YOUR-DOCKERHUB-USERNAME/iot-app:v1.0 webapp/

# Login to Docker Hub
docker login

# Push to Docker Hub
docker push YOUR-DOCKERHUB-USERNAME/iot-app:v1.0

# Tag as latest (optional)
docker tag YOUR-DOCKERHUB-USERNAME/iot-app:v1.0 YOUR-DOCKERHUB-USERNAME/iot-app:latest
docker push YOUR-DOCKERHUB-USERNAME/iot-app:latest
```

## Step 3: Create GitHub Repository

### On GitHub.com:
1. Create a new repository named: `iot-app` (or any name you prefer)
2. Clone it to your local machine
3. Add the following structure:

```
iot-app/
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── README.md
```

### Or use these commands:
```bash
# Create directory
mkdir iot-app
cd iot-app

# Initialize git
git init
git branch -M main

# Add deployment manifests (copy from p3/confs/)
cp ../p3/confs/deployment.yaml .
cp ../p3/confs/service.yaml .
cp ../p3/confs/ingress.yaml .

# Edit deployment.yaml to use your Docker image
# Change: image: wil42/playground:latest
# To:     image: YOUR-DOCKERHUB-USERNAME/iot-app:v1.0

# Create README
cat > README.md << 'EOF'
# IoT App - Kubernetes Manifests

GitOps repository for the IoT application.

## Manifests

- `deployment.yaml` - Kubernetes Deployment
- `service.yaml` - Kubernetes Service
- `ingress.yaml` - Kubernetes Ingress

## Deploy

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```
EOF

# Commit and push
git add .
git commit -m "Initial commit: Add Kubernetes manifests"
git remote add origin https://github.com/YOUR-GITHUB-USERNAME/iot-app.git
git push -u origin main
```

## Step 4: Update p3 to Use Your App

### Option A: Manual Deployment (Immediate Testing)

1. Update `p3/confs/deployment.yaml`:
   ```yaml
   spec:
     containers:
     - name: app
       image: YOUR-DOCKERHUB-USERNAME/iot-app:v1.0
   ```

2. Restart the deployment:
   ```bash
   kubectl set image deployment/playground playground=YOUR-DOCKERHUB-USERNAME/iot-app:v1.0 -n dev
   ```

### Option B: GitOps Deployment (Using ArgoCD)

1. Update `p3/confs/argocd-app.yaml`:
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: playground-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/YOUR-GITHUB-USERNAME/iot-app.git
       targetRevision: main
       path: .
     destination:
       server: https://kubernetes.default.svc
       namespace: dev
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```

2. Apply the ArgoCD application:
   ```bash
   kubectl apply -f p3/confs/argocd-app.yaml
   ```

3. ArgoCD will automatically deploy your app from GitHub!

## Step 5: Test Everything

### Test the Web App
```bash
# From your host machine
curl http://localhost:8888/

# Expected output:
# {"status":"ok","message":"Hello from IoT App - Python Flask","version":"v1"}
```

### Check Kubernetes Resources
```bash
# SSH into the Vagrant VM
vagrant ssh -c 'export KUBECONFIG=/home/vagrant/.kube/config && kubectl get all -n dev'

# Or from the VM directly
vagrant ssh
kubectl get all -n dev
```

### Monitor ArgoCD (Optional)
```bash
# Get ArgoCD password
cat p3/argocd-password.txt

# From the VM, port-forward to ArgoCD
vagrant ssh
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Open https://localhost:8080 (from your host, through vagrant port forwarding)
```

## Quick Reference

| Step | Command |
|------|---------|
| Test webapp locally | `cd webapp && python app.py` |
| Build Docker image | `docker build -t USERNAME/iot-app:v1.0 webapp/` |
| Push to Docker Hub | `docker push USERNAME/iot-app:v1.0` |
| Test with Kubernetes | `curl http://localhost:8888/` |
| View logs | `vagrant ssh && kubectl logs -n dev deployment/playground` |
| Restart app | `vagrant ssh && kubectl rollout restart deployment/playground -n dev` |

## Troubleshooting

### App not responding on localhost:8888
```bash
# Check if VM is running
vagrant status

# Check if port forwarding is working
netstat -an | grep 8888
```

### Docker push fails
```bash
# Make sure you're logged in
docker login

# Check Docker Hub credentials
cat ~/.docker/config.json
```

### ArgoCD not syncing
```bash
# Check ArgoCD application status
vagrant ssh
kubectl describe application -n argocd playground-app

# Force sync
argocd app sync playground-app
```

## Next Steps

1. Modify `webapp/app.py` to add more features
2. Update version tags as you iterate (v1.1, v1.2, etc.)
3. Push new Docker images and GitHub commits
4. ArgoCD will automatically deploy the latest version!

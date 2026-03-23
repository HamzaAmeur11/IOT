# Part 3: GitOps with ArgoCD

## 📌 Overview

This part introduces **GitOps** — a modern approach where your Git repository is the single source of truth for your application state. You'll use **ArgoCD** to continuously synchronize your cluster with Git, enabling CI/CD pipelines that automatically deploy changes when you push to GitHub.

### Architecture

```
┌─────────────────────┐
│   Your Git Repo     │
│ (Kubernetes Manifests)
│  deployment.yaml    │
│  service.yaml       │
└──────────┬──────────┘
           │ git push (from CI/CD)
           │ 
           ▼
┌─────────────────────────────────────┐
│   ArgoCD (GitOps Engine)            │
│   - Watches Git repo                │
│   - Detects changes                 │
│   - Auto-syncs to cluster           │
│   - Dashboard (UI)                  │
└──────────┬────────────────────────┬─┘
           │                        │
           ▼                        ▼
     ┌──────────┐          ┌─────────────────┐
     │ K3s      │          │  Dev Namespace  │
     │ Cluster  │          │  - Deployment   │
     │          │          │  - Service      │
     └──────────┘          │  - Ingress      │
                           └─────────────────┘
```

### GitOps Workflow

```
DEV WORKFLOW:
1. Developer makes code changes
2. Pushes to GitHub (app repo)
3. GitHub Actions builds Docker image
4. Pushes image to Docker Hub
5. Developer updates deployment.yaml in manifest repo
6. Commits & pushes to GitHub
7. ArgoCD detects change
8. ArgoCD applies new manifest to cluster
9. New version automatically deployed!
```

### Learning Objectives

- Understand GitOps principles
- Set up ArgoCD for automated deployments
- Configure ArgoCD to watch Git repositories
- Set up Helm charts for templating
- Test GitOps workflow (v1 → v2 upgrade)
- Use ArgoCD UI dashboard
- Implement automated CI/CD with Git

---

## 🛠️ Prerequisites

### Local Machine

- **Docker**: For building images locally
- **Docker Hub account**: To push images
- **GitHub account**: For Git repositories
- **kubectl**: For cluster access

### Required GitHub Repositories

You need to fork/create two repositories:

1. **App Repository** (source code):
   ```
   https://github.com/YOUR-USERNAME/iot-app
   (Contains: app.py, Dockerfile, requirements.txt)
   ```

2. **Manifest Repository** (Kubernetes manifests):
   ```
   https://github.com/YOUR-USERNAME/iot-manifests
   (Contains: deployment.yaml, service.yaml, ingress.yaml)
   ```

### Generate Personal Access Token

For pushing to GitHub from VM:
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Create token with `repo` scope
3. Save token securely

---

## 🚀 Quick Start (Automated)

### Step 1: Build & Push Docker Images

From your host machine:

```bash
cd p3

# Build v1 and v2 images and push to Docker Hub
bash scripts/build_versions.sh YOUR_DOCKER_HUB_USERNAME

# Example:
bash scripts/build_versions.sh john_doe
```

This script:
- Clones the app repo
- Builds v1 and v2 Docker images
- Pushes both to Docker Hub

### Step 2: Start K3d Cluster

```bash
# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Inside VM: Create k3d cluster
sudo bash /vagrant/scripts/setup_k3d_cluster.sh
```

### Step 3: Install ArgoCD

```bash
# Inside VM: Installing ArgoCD
sudo bash /vagrant/scripts/setup_argocd.sh

# This outputs the admin password - save it!
# ArgoCD will be accessible at: https://192.168.56.110:30080
```

### Step 4: Deploy Application via GitOps

```bash
# Inside VM: Deploy via ArgoCD
sudo bash /vagrant/scripts/deploy_app.sh
```

### Step 5: Test ArgoCD

```bash
# Inside VM: access application
curl http://localhost:8888/

# Expected response:
# {"message": "Hello from IoT App", "status": "ok", "version": "v1"}
```

---

## ✅ Testing & Verification

### Test 1: Verify ArgoCD Installation

```bash
# From host machine
export KUBECONFIG=$(pwd)/k3s.yaml

# Check ArgoCD pods
kubectl get pods -n argocd

# Expected:
NAME                                READY   STATUS    AGE
argocd-application-controller-0   1/1     Running   2m
argocd-dex-server-xxxxx           1/1     Running   2m
argocd-redis-xxxxx                1/1     Running   2m
argocd-repo-server-xxxxx          1/1     Running   2m
argocd-server-xxxxx               1/1     Running   2m
```

✅ **Success**: All ArgoCD pods running

### Test 2: Access ArgoCD UI Dashboard

```bash
# From host machine, in a new terminal
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Then open browser:
# https://localhost:8080
# Username: admin
# Password: Check p3/argocd-password.txt (saved during setup)
```

✅ **Success**: Can login and see ArgoCD dashboard

### Test 3: Verify Application Deployed

```bash
export KUBECONFIG=$(pwd)/k3s.yaml

# Check if app is in dev namespace
kubectl get all -n dev

# Expected:
NAME                           READY   STATUS    RESTARTS   AGE
pod/playground-xxxxx-xxxxx     1/1     Running   0          2m

NAME                      TYPE        CLUSTER-IP      PORT(S)           AGE
service/playground       ClusterIP   10.43.xxx.xxx   8888/TCP          2m
service/playground-live  NodePort    10.43.xxx.xxx   8888:30081/TCP    2m

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/playground         1/1     1            1           2m
```

✅ **Success**: Application deployed in dev namespace

### Test 4: Test Application Endpoint

```bash
# From host machine
curl http://192.168.56.110:30081/

# Expected response:
{"message": "Hello from IoT App - version 1", "status": "ok", "version": "v1"}
```

✅ **Success**: Application responding with v1

### Test 5: Verify ArgoCD Application Status

```bash
export KUBECONFIG=$(pwd)/k3s.yaml

# Check ArgoCD application
kubectl get application -n argocd

# Expected:
NAME          SYNC STATUS   HEALTH STATUS
playground    Synced        Healthy
```

✅ **Success**: ArgoCD application synchronized

### Test 6: ArgoCD Sync Policy Verification

```bash
# Describe the ArgoCD application
kubectl describe application playground -n argocd

# Look for:
# Auto-Sync: Enabled
# Auto-Prune: Enabled
# Self-Heal: Enabled
```

✅ **Success**: Auto-sync enabled for GitOps workflow

### Test 7: GitOps Workflow Test - v1 to v2 Upgrade

**Simple Method** (Recommended - No GitHub needed):

```bash
# From host machine
export KUBECONFIG=$(pwd)/k3s.yaml

# Update deployment to use v2 image
kubectl set image deployment/playground -n dev \
  playground=YOUR_DOCKER_HUB_USERNAME/iot-app:v2

# Wait for new pod
kubectl wait --for=condition=ready pod -l app=playground -n dev --timeout=60s

# Verify v2 is running
curl http://192.168.56.110:30081/

# Expected response:
{"message": "Hello from IoT App - version 2", "status": "ok", "version": "v2"}
```

**Full GitOps Method** (Using GitHub):

```bash
# From host machine (or VM)
cd YOUR_CLONED_MANIFESTS_REPO

# Update deployment.yaml
sed -i 's/iot-app:v1/iot-app:v2/' deployment.yaml

# Commit and push
git add deployment.yaml
git commit -m "upgrade to v2"
git push

# Watch ArgoCD sync (check UI or):
kubectl get application playground -n argocd -w

# After sync completes, test:
curl http://192.168.56.110:30081/
```

✅ **Success**: v2 deployed via GitOps

### Test 8: Auto-Revert Test

```bash
# Delete deployment manually
kubectl delete deployment playground -n dev

# Wait 5 seconds - ArgoCD should auto-heal
sleep 5

# Check if it's back
kubectl get deployment -n dev

# Expected:
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
playground   1/1     1            1           5s
```

✅ **Success**: Self-healing works

### Test 9: Manual Sync in ArgoCD UI

1. Open ArgoCD UI (https://localhost:8080)
2. Click on "playground" application
3. Click "Refresh" to force sync
4. Check Status changes to "Synced"

✅ **Success**: Can manually sync from UI

### Test 10: Check Resource Utilization

```bash
# From inside VM
kubectl top nodes
kubectl top pods -n argocd
kubectl top pods -n dev
```

✅ **Success**: Resource usage is within limits

---

## 📊 Full GitOps Test Suite

Save as `test_p3_gitops.sh`:

```bash
#!/bin/bash
set -e

export KUBECONFIG=$(pwd)/k3s.yaml

echo "========================================="
echo "Part 3: GitOps Testing Suite"
echo "========================================="

# Wait for cluster
echo ""
echo "➤ Waiting for cluster..."
kubectl wait --for=condition=Ready node --all --timeout=300s

# Test 1: ArgoCD installation
echo ""
echo "✓ Test 1: ArgoCD Installation"
ARGOCD_PODS=$(kubectl get pods -n argocd -o jsonpath='{.items | length}')
if [ "$ARGOCD_PODS" -ge 5 ]; then
  echo "✓ ArgoCD pods running ($ARGOCD_PODS pods)"
else
  echo "✗ Not enough ArgoCD pods found ($ARGOCD_PODS/5)"
  exit 1
fi

# Test 2: Application namespace
echo ""
echo "✓ Test 2: Dev Namespace"
kubectl get namespace dev
echo "✓ Dev namespace exists"

# Test 3: Application deployed
echo ""
echo "✓ Test 3: Application Deployment"
PODS=$(kubectl get pods -n dev -o jsonpath='{.items | length}')
if [ "$PODS" -ge 1 ]; then
  echo "✓ Application pods running ($PODS pods)"
else
  echo "✗ No application pods found"
  exit 1
fi

# Test 4: Pods are ready
echo ""
echo "✓ Test 4: Waiting for Pods Ready"
kubectl wait --for=condition=ready pod -n dev --all --timeout=60s
echo "✓ All dev pods are ready"

# Test 5: Service endpoints
echo ""
echo "✓ Test 5: Service Endpoints"
ENDPOINTS=$(kubectl get endpoints -n dev playground -o jsonpath='{.subsets[0].addresses | length}' 2>/dev/null || echo 0)
if [ "$ENDPOINTS" -gt 0 ]; then
  echo "✓ Service has active endpoints"
else
  echo "✗ No endpoints found"
  exit 1
fi

# Test 6: ArgoCD application status
echo ""
echo "✓ Test 6: ArgoCD Application"
SYNC_STATUS=$(kubectl get application playground -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
if [ "$SYNC_STATUS" == "Synced" ]; then
  echo "✓ Application is Synced"
else
  echo "! Application status: $SYNC_STATUS (may be syncing)"
fi

# Test 7: Port forward and test endpoint
echo ""
echo "✓ Test 7: Application Endpoint Test"
POD=$(kubectl get pods -n dev -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward -n dev "pod/$POD" 9999:8888 &
PF_PID=$!
sleep 2

if curl -s http://localhost:9999/ | grep -q "version"; then
  echo "✓ Application endpoint responding"
  RESPONSE=$(curl -s http://localhost:9999/)
  echo "Response: $RESPONSE"
else
  echo "✗ Application not responding"
  kill $PF_PID 2>/dev/null || true
  exit 1
fi

kill $PF_PID 2>/dev/null || true

# Test 8: Git repository configuration
echo ""
echo "✓ Test 8: Git Configuration"
GIT_REPO=$(kubectl get application playground -n argocd -o jsonpath='{.spec.source.repoURL}' 2>/dev/null || echo "Not found")
echo "Repository: $GIT_REPO"

echo ""
echo "========================================="
echo "✅ All GitOps tests passed!"
echo "========================================="
```

Run it:
```bash
bash test_p3_gitops.sh
```

---

## 🔧 Useful Commands

### ArgoCD CLI

```bash
# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login to ArgoCD
argocd login 192.168.56.110:30080 --insecure --username admin --password <PASSWORD>

# List applications
argocd app list

# Sync application
argocd app sync playground

# Get application details
argocd app get playground

# Set auto-sync
argocd app set playground --sync-policy automated
```

### Kubernetes Commands

```bash
# Watch ArgoCD application sync
kubectl get applications -n argocd -w

# View application events
kubectl get events -n dev --sort-by='.lastTimestamp'

# Check deployment status
kubectl rollout status deployment/playground -n dev

# View pod logs
kubectl logs -n dev -l app=playground -f

# Check image used
kubectl get pod -n dev -o jsonpath='{.items[0].spec.containers[0].image}'
```

### Git Management

```bash
# Clone manifest repo
git clone https://github.com/YOUR-USERNAME/iot-manifests
cd iot-manifests

# View current deployment
cat deployment.yaml

# Update image version
sed -i 's/:v1/:v2/g' deployment.yaml

# Commit and push
git add .
git commit -m "Update to v2"
git push

# ArgoCD will sync automatically (or manually: argocd app sync playground)
```

---

## 🐛 Troubleshooting

### Problem: ArgoCD pod not running

```bash
# Check pod status
kubectl describe pod -n argocd argocd-server-xxxxx

# Check logs
kubectl logs -n argocd argocd-server-xxxxx

# Check resource limits
kubectl get pods -n argocd -o json | jq '.items[].spec.containers[].resources'
```

### Problem: ArgoCD shows "OutOfSync"

This is normal after pushing to Git. ArgoCD detects the change:

```bash
# Manually sync
kubectl apply -f /vagrant/confs/deployment.yaml -n dev

# Or via UI: Click "Sync" in ArgoCD dashboard
```

### Problem: Application not deploying

```bash
# Check ArgoCD repo-server logs
kubectl logs -n argocd deployment/argocd-repo-server

# Check if Git repo is accessible
kubectl get application playground -n argocd -o yaml

# Verify Git credentials if private repo
kubectl get secret -n argocd | grep -i git
```

### Problem: Port forwarding doesn't work

```bash
# Try from inside VM
vagrant ssh
curl http://localhost:8888/

# If that works, check your host's firewall
# Try direct IP access
curl http://192.168.56.110:30081/
```

### Problem: Image doesn't update

```bash
# Check if pod uses correct image
kubectl get pod -n dev -o yaml | grep -i image

# Force pod restart
kubectl delete pod -n dev -l app=playground

# Wait for new pod
kubectl wait --for=condition=ready pod -n dev --all --timeout=60s
```

---

## 📚 Understanding GitOps & ArgoCD

### GitOps Principles

| Principle | Meaning |
|-----------|---------|
| **Declarative** | Describe desired state in Git |
| **Version Controlled** | All changes tracked in Git |
| **Automatically Applied** | GitOps tool syncs desired state |
| **Observable** | Tools provide visibility into state |
| **Reconciliation** | System constantly works toward desired state |

### ArgoCD Features

| Feature | Purpose |
|---------|---------|
| **Auto-Sync** | Automatically apply Git changes |
| **Self-Healing** | Recreate deleted resources |
| **ApplicationController** | Watches Git and cluster |
| **Repo-Server** | Fetches and renders Git manifests |
| **Server** | REST API and UI dashboard |

### ArgoCD Application YAML

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: playground        # App name
  namespace: argocd      # ArgoCD namespace
spec:
  project: default
  source:
    repoURL: https://github.com/USERNAME/iot-manifests
    targetRevision: HEAD  # Point to main branch
    path: .              # All yamls in repo root
  destination:
    server: https://kubernetes.default.svc
    namespace: dev       # Deploy to dev namespace
  syncPolicy:
    automated:
      prune: true        # Delete removed manifests
      selfHeal: true     # Restore deleted resources
    syncOptions:
    - CreateNamespace=true  # Create namespace if missing
```

---

## 🎯 GitOps Workflow Example

### Starting State

```
GitHub Repo:
├── deployment.yaml  (image: v1)
├── service.yaml
└── ingress.yaml

K3s Cluster: (synced)
├── deployment running image: v1
├── service
└── ingress
```

### After Code Change

```
Developer:
1. Code changes in app repo
2. Git push
3. GitHub Actions triggers
4. Builds image v2
5. Pushes docker image
6. Commits deployment.yaml update

GitHub Repo:
├── deployment.yaml  (image: v2)  ← CHANGED
├── service.yaml
└── ingress.yaml

ArgoCD:
1. Detects repo change
2. Compares Git vs Cluster
3. Sees image version mismatch
4. Applies new deployment
5. Kills old pod, starts new pod

K3s Cluster: (synced)
├── deployment running image: v2  ← UPDATED
├── service
└── ingress
```

---

## 📊 Repository Structure

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

---

## 🎓 Next Steps After Part 3

### Further GitOps Learning

1. **Add webhooks**: Real-time sync on Git push
2. **Multi-environment**: Dev, staging, prod repos
3. **Helm charts**: Templating Kubernetes manifests
4. **Access control**: RBAC for applications
5. **Notifications**: Slack/email on sync

### Production Considerations

- Use GitHub Enterprise or GitLab
- Implement branch protection rules
- Add code review requirements
- Use separate repos per environment
- Implement kustomize or Helm
- Add monitoring and alerts

---

## 📖 Further Reading

- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://gitops.tech/)
- [Kubernetes Patterns](https://kubernetes.io/docs/concepts/architecture/)
- [GitHub Actions CI/CD](https://github.com/features/actions)

---

## ✨ Summary

**Part 3 teaches you**:
- GitOps principles and philosophy
- ArgoCD installation and configuration
- Automated synchronization with Git
- Git-based deployment workflows
- Auto-healing and self-reconciliation
- Upgrading applications via Git
- Multi-environment management

**Time to complete**: 30-60 minutes

**Difficulty**: ⭐⭐⭐⭐ (Advanced)

---

**Ready to test? Start with Test 1 above!** ✅

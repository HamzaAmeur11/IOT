# P3 Automated Testing Guide

## Quick Start - Simple Version (Recommended)

**Fastest way to test v1 → v2 upgrade:**

```bash
# From your host machine
cd /home/fullname/Documents/42Projects/IOT/p3

# Run the simple test inside the VM
vagrant ssh -c "bash /vagrant/scripts/test_simple.sh"
```

**What it does:**
1. ✓ Verifies v1 is running
2. ✓ Updates deployment to v2
3. ✓ Waits for new pod
4. ✓ Tests v2 endpoint
5. ✓ Health check

**Result:** Shows old/new pod and version change

---

## Prerequisites for Both Scripts

Make sure you have:
- ✓ VM running (`vagrant up`)
- ✓ v1 image on Docker Hub: `hdameur12/iot-app:v1`
- ✓ v2 image on Docker Hub: `hdameur12/iot-app:v2`
- ✓ GitHub manifests repo: `https://github.com/HamzaAmeur11/Hameur-iot-manifests`
- ✓ GitHub app repo: `https://github.com/HamzaAmeur11/iot-app`

---

## Advanced Version - Full GitOps Test

**For end-to-end GitOps automation (builds v2 and pushes to GitHub):**

```bash
# From your host machine
cd /home/fullname/Documents/42Projects/IOT/p3

# Build, push to Docker Hub, update GitHub, and test
bash scripts/test_gitops.sh
```

**What it does:**
1. ✓ Clones app repo and builds v2 image
2. ✓ Pushes v2 to Docker Hub
3. ✓ Clones manifest repo and updates deployment.yaml
4. ✓ Pushes changes to GitHub
5. ✓ Creates ArgoCD app and waits for sync
6. ✓ Validates v2 is running
7. ✓ Health check

**Requires:** Docker Hub and GitHub credentials

---

## Manual Testing (If Scripts Fail)

SSH into VM:
```bash
vagrant ssh
```

Then manually test:
```bash
# View current version
curl http://localhost:8888/

# Check pod details
kubectl get pods -n dev -o wide

# Update to v2 manually
kubectl set image deployment/playground -n dev \
  playground=hdameur12/iot-app:v2

# Wait for pod
kubectl wait --for=condition=ready pod -l app=playground -n dev --timeout=60s

# Verify v2
curl http://localhost:8888/
```

---

## Troubleshooting

### Test fails with "Connection refused"
```bash
# Check if app is running
kubectl get pods -n dev

# Check pod logs
kubectl logs -n dev deployment/playground
```

### Pod stuck in ImagePullBackOff
```bash
# Check image exists on Docker Hub
docker pull hdameur12/iot-app:v2

# Check pod events
kubectl describe pod -n dev -l app=playground
```

### ArgoCD not syncing (full test only)
```bash
# Check ArgoCD status
kubectl get application -n argocd

# Check repo-server logs
kubectl logs -n argocd deployment/argocd-repo-server
```

---

## Expected Output

**Simple test success:**
```
========================================
P3 GitOps Test: v1 → v2 Automation
========================================

→ Testing current version (v1)...
Current: "version":"v1"
✓ v1 is running

→ Checking current pod...
Current pod: playground-7d98595998-w2qs5
Current image: hdameur12/iot-app:v1

→ Updating deployment to v2...
✓ Deployment updated to v2

→ Waiting for new pod to be ready (max 60s)...
New pod: playground-8f9c7d4f2a-b3k9l

→ Verifying version changed to v2...
New version: "version":"v2"
✓ v2 is now running

→ Health check...
Health: "status":"healthy"
✓ Application is healthy

========================================
✓ Tests Passed! v1 → v2 upgrade successful
========================================
```

---

## Script Locations

```
p3/scripts/
├── test_simple.sh      # Quick v1→v2 test (RECOMMENDED)
├── test_gitops.sh      # Full GitOps workflow test
├── install_tools.sh
├── setup_k3d_cluster.sh
├── setup_argocd.sh
└── deploy_app.sh
```

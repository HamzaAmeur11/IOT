# P3 Quick Reference - Common Commands Cheatsheet

## VM Management

```bash
# Start VM
cd /path/to/p3
vagrant up

# SSH into VM
vagrant ssh

# Stop VM
vagrant halt

# Destroy VM
vagrant destroy

# Rebuild/redeploy everything
vagrant destroy -f && vagrant up
```

## Kubernetes - Namespaces

```bash
# List all namespaces
kubectl get ns

# Expected output:
# NAME      STATUS   AGE
# argocd    Active   19h
# default   Active   19h
# dev       Active   19h
# kube-xxx  Active   19h
```

## Kubernetes - Pods & Deployments

```bash
# List pods in all namespaces
kubectl get pods -A

# List pods in dev namespace
kubectl get pods -n dev

# Describe a pod
kubectl describe pod POD-NAME -n dev

# View pod logs
kubectl logs POD-NAME -n dev

# Watch pod status (live update)
kubectl get pods -n dev -w

# Execute command in pod
kubectl exec -it POD-NAME -n dev -- bash
```

## Kubernetes - Services & Ingress

```bash
# List services
kubectl get svc -n dev

# Describe service
kubectl describe svc playground -n dev

# Port forward to service (access from host)
kubectl port-forward svc/playground -n dev 8888:8888

# List ingress
kubectl get ingress -n dev
```

## Docker Hub

```bash
# Login
docker login

# Build image
docker build -t YOUR-USERNAME/iot-app:v1 .

# Push image
docker push YOUR-USERNAME/iot-app:v1

# Pull image
docker pull YOUR-USERNAME/iot-app:v1

# List local images
docker images

# View image info
docker images YOUR-USERNAME/iot-app
```

## ArgoCD CLI

```bash
# Get ArgoCD password (from host/VM)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Save to file
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt

# List applications
kubectl get applications -n argocd

# Get application details
argocd app get iot-app

# Sync application
argocd app sync iot-app

# Refresh application (check for updates)
argocd app get iot-app --refresh

# Delete application
argocd app delete iot-app -n argocd
```

## ArgoCD Dashboard

```bash
# Port forward from VM
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access from host browser: https://localhost:8080
# Username: admin
# Password: (from above command)
```

## Git Commands

```bash
# Clone repository
git clone https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git

# Navigate to repo
cd YOUR-USERNAME-iot-manifests

# Check status
git status

# Add changes
git add .
# or specific file:
git add deployment.yaml

# Commit changes
git commit -m "Update app version to v2"

# Push to GitHub
git push

# Verify push was successful
git log --oneline
```

## Testing Application Versions

```bash
# Test v1
curl http://localhost:8888/
# Expected: {"status":"ok","message":"...","version":"v1"}

# After updating GitHub repo to v2 and syncing:
curl http://localhost:8888/
# Expected: {"status":"ok","message":"...","version":"v2"}

# Health check endpoint
curl http://localhost:8888/health
# Expected: {"status":"healthy"}
```

## Debugging & Troubleshooting

```bash
# Get cluster info
kubectl cluster-info

# Get nodes
kubectl get nodes

# Describe node
kubectl describe node NODE-NAME

# Get all resources in namespace
kubectl get all -n dev

# Check recent events
kubectl get events -n dev

# Describe application (ArgoCD)
kubectl describe application iot-app -n argocd

# Check if repo is accessible
argocd repo add https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git

# Sync with error details
argocd app sync iot-app --verbose
```

## K3d Cluster Management

```bash
# List k3d clusters
k3d cluster list

# Get kubeconfig
k3d kubeconfig get iot-cluster

# Delete cluster
k3d cluster delete iot-cluster

# Create new cluster
k3d cluster create my-cluster --servers 1 --agents 2
```

## File Locations (in VM)

```
/home/vagrant/.kube/config          # Kubeconfig file
/vagrant/confs/                     # Shared manifests from host
/vagrant/argocd-password.txt        # ArgoCD admin password
~/.docker/config.json               # Docker Hub credentials
```

## Quick Workflow: Update Application Version

```bash
# 1. In your manifests GitHub repo
cd ~/YOUR-USERNAME-iot-manifests
vim deployment.yaml
# Change: image: YOUR-USERNAME/iot-app:v1 → v2

# 2. Commit and push
git add deployment.yaml
git commit -m "Update to v2"
git push

# 3. Check ArgoCD syncs automatically (within ~1 minute)
argocd app get iot-app

# 4. Verify pod restarted
kubectl get pods -n dev

# 5. Test new version
curl http://localhost:8888/
```

## Environment Variables in App

The Flask app reads these environment variables (set in Dockerfile):

```dockerfile
ENV APP_VERSION=v1              # Shown in API response
ENV APP_MESSAGE="Hello..."      # Shown in API response
```

To create v2, you would change `v1` to `v2` in the Dockerfile or pass via deployment.

## Useful Tips

- **If you make mistakes**: `vagrant destroy -f && vagrant up` rebuilds everything
- **Speed up VM**: 4GB RAM and 2 CPUs minimal (set in Vagrantfile)
- **Port forwarding conflicts**: If 8080/8888 in use, adjust in Vagrantfile
- **GitHub auth issues**: For public repos, no Personal Access Token needed
- **ArgoCD not syncing**: Force refresh with `argocd app get iot-app --refresh`
- **Pod keeps restarting**: Check `kubectl logs POD-NAME -n dev` for errors

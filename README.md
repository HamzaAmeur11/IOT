# IoT - Inception of Things

A comprehensive guide to setting up Kubernetes clusters with K3s, deploying applications with Ingress routing, and implementing GitOps with ArgoCD.

## 📋 Project Overview

This project is divided into three parts, each building upon Kubernetes and DevOps concepts:

- **Part 1**: K3s cluster with Server and Worker nodes
- **Part 2**: K3s Server with application deployments and Ingress routing
- **Part 3**: K3s with ArgoCD for GitOps continuous deployment
- **Bonus**: Additional advanced features (optional)

## 🛠️ Prerequisites

- **VirtualBox**: For VM virtualization
- **Vagrant**: For VM provisioning (version 2.0+)
- **kubectl**: Kubernetes command-line tool (optional, for local access)
- **System Requirements**:
  - Part 1 & 2: ~1.5GB RAM
  - Part 3: ~2GB RAM

## 📁 Project Structure

```
IOTT/
├── p1/                          # Part 1: K3s Cluster
│   ├── Vagrantfile
│   ├── scripts/
│   │   ├── install_k3s_server.sh
│   │   └── install_k3s_worker.sh
│   └── [generated files]
│
├── p2/                          # Part 2: Applications with Ingress
│   ├── Vagrantfile
│   ├── scripts/
│   │   └── install_k3s.sh
│   ├── app1.yaml
│   ├── app2.yaml
│   ├── app3.yaml
│   └── ingress.yaml
│
├── p3/                          # Part 3: ArgoCD & GitOps
│   ├── Vagrantfile
│   ├── scripts/
│   │   ├── install_k3s.sh
│   │   └── deploy_app.sh
│   ├── confs/
│   │   ├── app.yaml
│   │   └── argocd-app.yaml
│   └── QUICKSTART.md
│
└── bonus/                       # Bonus features (optional)
```

---

## 🚀 Part 1: K3s Cluster with Server and Worker

### Overview
Sets up a two-node Kubernetes cluster using K3s:
- **Server Node (HAMEUR-S)**: Controller node at `192.168.42.110`
- **Worker Node (HAMEUR-SW)**: Worker node at `192.168.42.111`

### Features
- K3s lightweight Kubernetes distribution
- Server-worker architecture
- Automatic node joining with token authentication
- SSH key-based access between nodes
- Flannel CNI for networking

### Setup

```bash
cd p1
vagrant up
```

### Verification

```bash
# Access server node
vagrant ssh HAMEUR-S

# Check nodes
kubectl get nodes

# Expected output:
# NAME        STATUS   ROLE                  AGE   VERSION
# HAMEUR-S    Ready    control-plane,master  ...   v1.x.x
# HAMEUR-SW   Ready    <none>                ...   v1.x.x
```

### Access from Host

```bash
export KUBECONFIG=$(pwd)/k3s.yaml
kubectl get nodes
```

### Cleanup

```bash
vagrant destroy -f
```

---

## 🌐 Part 2: Application Deployment with Ingress

### Overview
Single K3s server with three web applications and Ingress routing using Traefik.

### Architecture
- **Server Node**: `192.168.42.110`
- **Three Applications**: app1, app2, app3 (nginx-based)
- **Ingress Controller**: Traefik (built-in with K3s)

### Features
- Host-based routing (app1.com, app2.com)
- Default backend (app3)
- ConfigMap-based HTML content
- NodePort and ClusterIP services

### Setup

```bash
cd p2
vagrant up
```

### Deploy Applications

```bash
# From host machine
export KUBECONFIG=$(pwd)/k3s.yaml

kubectl apply -f app1.yaml
kubectl apply -f app2.yaml
kubectl apply -f app3.yaml
kubectl apply -f ingress.yaml
```

Or from within the VM:

```bash
vagrant ssh -c "kubectl apply -f /vagrant/app1.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/app2.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/app3.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/ingress.yaml"
```

### Testing

Add entries to `/etc/hosts`:

```bash
echo "192.168.42.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.42.110 app2.com" | sudo tee -a /etc/hosts
```

Test the applications:

```bash
curl app1.com        # Should display "app1"
curl app2.com        # Should display "app2"
curl 192.168.42.110  # Should display "app3" (default)
```

### Verification

```bash
vagrant ssh -c "kubectl get pods"
vagrant ssh -c "kubectl get svc"
vagrant ssh -c "kubectl get ingress"
```

### Cleanup

```bash
vagrant destroy -f
```

---

## 🔄 Part 3: GitOps with ArgoCD

### Overview
K3s cluster with ArgoCD for continuous deployment and GitOps workflows.

### Architecture
- **Server Node**: `192.168.42.110`
- **ArgoCD**: GitOps deployment tool
- **Sample Application**: "Wil's Playground"

### Features
- ArgoCD UI dashboard
- Automated application synchronization
- Self-healing and auto-pruning
- Git-based declarative deployments
- NodePort access for services

### Setup

```bash
cd p3
vagrant up
```

The setup script will:
1. Install K3s
2. Install ArgoCD
3. Configure ArgoCD as NodePort service (port 30080)
4. Create `dev` namespace
5. Save ArgoCD admin password to `argocd-password.txt`

### Access Information

**ArgoCD Dashboard**:
- URL: https://192.168.42.110:30080
- Username: `admin`
- Password: Check `p3/argocd-password.txt`

**Sample Application**:
- URL: http://192.168.42.110:30081

### Deploy Sample Application

```bash
# Direct deployment (for testing)
vagrant ssh -c "kubectl apply -f /vagrant/confs/app.yaml"

# Verify deployment
vagrant ssh -c "kubectl get pods -n dev"
vagrant ssh -c "kubectl get svc -n dev"
```

### GitOps Workflow

1. **Create a Git repository** with your application manifests:
   ```
   my-app-repo/
   └── app.yaml
   ```

2. **Update ArgoCD Application** (`confs/argocd-app.yaml`):
   ```yaml
   source:
     repoURL: https://github.com/YOUR-USERNAME/your-repo.git
     targetRevision: HEAD
     path: .
   ```

3. **Deploy ArgoCD Application**:
   ```bash
   vagrant ssh -c "kubectl apply -f /vagrant/confs/argocd-app.yaml"
   ```

4. **Watch ArgoCD sync** via UI or CLI:
   ```bash
   vagrant ssh -c "kubectl get applications -n argocd"
   ```

5. **Make changes** to your Git repo - ArgoCD will automatically sync!

### Verification

```bash
# Check ArgoCD pods
vagrant ssh -c "kubectl get pods -n argocd"

# Check application pods
vagrant ssh -c "kubectl get pods -n dev"

# Check ArgoCD applications
vagrant ssh -c "kubectl get applications -n argocd"
```

### ArgoCD CLI (Optional)

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# Login
argocd login 192.168.42.110:30080 --insecure
```

### Cleanup

```bash
vagrant destroy -f
```

---

## 🎁 Bonus Part (Optional)

Advanced features and enhancements:

- GitLab CI/CD pipeline integration
- Helm charts for application deployment
- Monitoring with Prometheus/Grafana
- Service mesh (Istio/Linkerd)
- Advanced security configurations
- Multi-environment deployments

---

## 🔧 Common Commands

### Vagrant Commands

```bash
vagrant up           # Start VMs
vagrant halt         # Stop VMs
vagrant reload       # Restart VMs
vagrant destroy -f   # Delete VMs
vagrant ssh          # SSH into default VM
vagrant ssh <name>   # SSH into specific VM
vagrant status       # Check VM status
```

### Kubernetes Commands

```bash
# Pods
kubectl get pods [-n namespace]
kubectl describe pod <pod-name>
kubectl logs <pod-name>

# Services
kubectl get svc
kubectl describe svc <service-name>

# Ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# Nodes
kubectl get nodes
kubectl describe node <node-name>

# Applications (ArgoCD)
kubectl get applications -n argocd
kubectl describe application <app-name> -n argocd
```

---

## 🐛 Troubleshooting

### VMs Won't Start

```bash
# Check VirtualBox
VBoxManage list runningvms

# Check logs
vagrant up --debug

# Try with different provider
vagrant up --provider=virtualbox
```

### Kubectl Connection Issues

```bash
# Fix kubeconfig server URL
sed -i 's/127.0.0.1/192.168.42.110/g' k3s.yaml

# Use from inside VM
vagrant ssh -c "kubectl get nodes"

# Check if K3s is running
vagrant ssh -c "sudo systemctl status k3s"
```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resources
kubectl top nodes  # Requires metrics-server
```

### Ingress Not Working

```bash
# Check Traefik is running
kubectl get pods -n kube-system | grep traefik

# Check ingress configuration
kubectl describe ingress <ingress-name>

# Check service endpoints
kubectl get endpoints
```

### ArgoCD Issues

```bash
# Reset password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Check ArgoCD pods
kubectl get pods -n argocd

# Restart ArgoCD server
kubectl rollout restart deployment argocd-server -n argocd
```

---

## 📚 Key Concepts

### K3s
- Lightweight Kubernetes distribution
- Single binary, low resource usage
- Perfect for development, edge, and IoT
- Built-in components (Traefik, CoreDNS)

### Ingress
- Routes external HTTP/HTTPS traffic to services
- Host and path-based routing
- SSL/TLS termination
- Load balancing

### ArgoCD
- GitOps continuous delivery tool
- Declarative infrastructure as code
- Automated synchronization
- Self-healing capabilities
- Multi-cluster support

### GitOps
- Git as single source of truth
- Declarative configurations
- Automated deployments
- Version control for infrastructure
- Easy rollbacks

---

## 📖 Additional Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

---

## 📝 Notes

- All VMs use Ubuntu 22.04 (bento/ubuntu-22.04)
- Private network range: 192.168.42.0/24
- Generated files (k3s.yaml, tokens, keys) are in .gitignore
- VMs are ephemeral - destroying them removes all data
- For production use, consider persistent storage solutions
- Self-signed certificates are normal for local development

---

## ✅ Project Completion Checklist

- [ ] Part 1: K3s cluster with 2 nodes running
- [ ] Part 1: Both nodes show as Ready in kubectl
- [ ] Part 2: K3s server with applications deployed
- [ ] Part 2: Ingress routing working for all apps
- [ ] Part 2: Can access apps via browser/curl
- [ ] Part 3: ArgoCD installed and accessible
- [ ] Part 3: Sample application deployed
- [ ] Part 3: ArgoCD UI accessible and functional
- [ ] All parts: Documentation complete
- [ ] All parts: VMs can be cleanly destroyed and recreated

---

## 🤝 Contributing

This is an educational project. Feel free to experiment, break things, and learn!

## 📄 License

This project is for educational purposes.

---

**Happy Kubernetes Learning! 🚀**
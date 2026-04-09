# 🚀 IoT - Inception of Things

A **progressive Kubernetes & DevOps learning project** with 4 hands-on parts. Start with a basic cluster, deploy apps with ingress, implement GitOps, and add observability.

**✅ Latest**: kubectl alias works on all VMs | SSL certs fixed with `--tls-san` | Host kubeconfig access enabled

---

## 🎯 What You Get

| Part | What | Cluster | VMs | Time |
|------|------|---------|-----|------|
| **1** | K3s multi-node cluster | 2x K3s nodes | HAMEUR-S, HAMEUR-SW | 15-30m |
| **2** | Kubernetes Deployments + Traefik Ingress | 1x K3s | HAMEUR-S | 20-40m |
| **3** | GitOps with ArgoCD + K3d | 1x K3d (3 nodes in Docker) | HAMEUR-P3 | 30-60m |
| **Bonus** | Prometheus metrics + Grafana dashboards | 1x K3s with monitoring | HAMEUR-BONUS | 30-50m |

---

## 🚀 Start Here

### Prerequisites
- **VirtualBox** (6.0+)
- **Vagrant** (2.0+)
- **kubectl** (or use from VM)
- **Git**
- **8GB RAM** minimum (12GB+ recommended)

### Quick Start

```bash
# Part 1: K3s Cluster with 2 nodes
cd p1
vagrant up
export KUBECONFIG=$(pwd)/output/k3s.yaml
k get nodes  # See both nodes Ready

# Part 2: Deploy 3 apps with Ingress
cd ../p2
export KUBECONFIG=$(pwd)/k3s.yaml
vagrant up
k apply -f app1.yaml app2.yaml app3.yaml ingress.yaml
curl http://192.168.56.110  # Test app3

# Part 3: GitOps with ArgoCD
cd ../p3
export KUBECONFIG=$(pwd)/k3s.yaml
vagrant up && vagrant ssh
k get nodes  # 3-node K3d cluster in Docker
# ArgoCD auto-deploys app from GitHub

# Bonus: Prometheus + Grafana
cd ../bonus
export KUBECONFIG=$(pwd)/k3s.yaml
vagrant up
k get pods -n monitoring  # Check monitoring stack
# Access Grafana at http://localhost:30300
```

---

## 📖 Part Details

### Part 1: K3s Cluster Setup
**Goal**: Learn Kubernetes cluster architecture with 2 nodes

- Creates **2 VMs**: HAMEUR-S (control plane), HAMEUR-SW (worker)
- Installs K3s server on HAMEUR-S, joins HAMEUR-SW as agent
- Fixed networking with flannel CNI on eth1
- SSL certificates include SERVER_IP (192.168.56.110) via `--tls-san`
- Output: kubeconfig in `p1/output/k3s.yaml`

**Key Files**:
- `scripts/install_k3s_server.sh` - Server setup with k alias + KUBECONFIG
- `scripts/install_k3s_worker.sh` - Worker join with SSH key setup
- `ips.conf` - IP addresses

**What You'll Learn**:
- Multi-node Kubernetes cluster setup
- kubectl basics and node management
- K3s lightweight Kubernetes
- Networking between nodesoutput

---

### Part 2: Applications & Ingress
**Goal**: Deploy real apps with routing

- Creates **1 VM**: HAMEUR-S (1 vCPU, 1GB RAM)
- Installs K3s with Traefik ingress controller (built-in)
- Deploys 3 sample nginx apps via ConfigMaps
- Sets up ingress rules: `app1.com`, `app2.com`, default route
- Apps accessible at http://192.168.56.110

**Key Files**:
- `app1.yaml`, `app2.yaml`, `app3.yaml` - ConfigMap + Deployment
- `ingress.yaml` - Traefik ingress routing
- `scripts/install_k3s.sh` - K3s + app deployment
- `ips.conf` - Server IPoutput

**What You'll Learn**:
- Kubernetes Deployments and Pods
- ConfigMaps for app configuration
- Services and networking
- Ingress and host-based routing
- Traefik controller basics

---

### Part 3: GitOps with ArgoCD
**Goal**: Deploy apps automatically from Git

- Creates **1 VM**: HAMEUR-P3 (2 vCPU, 4GB RAM)
- Installs K3d (Kubernetes in Docker) with 3 nodes
- Sets up ArgoCD in `argocd` namespace
- Deploys webapp with v1 and v2 versions
- Auto-syncs from GitHub (you control via Git)
- Port forwarding: 8080 (ArgoCD), 8888 (app)

**Key Files**:
- `confs/deployment.yaml` - App deployment
- `confs/argocd-app.yaml` - ArgoCD Application CRD
- `scripts/setup_k3d_cluster.sh` - K3d cluster creation
- `scripts/setup_argocd.sh` - ArgoCD namespace + installation
- `scripts/deploy_app.sh` - Deploy initial version
- `scripts/setup_portforward.sh` - Pod networking
- `webapp/` - Source app code

**What You'll Learn**:
- GitOps principles and workflow
- ArgoCD declarative deployment
- K3d (Kubernetes in Docker)
- Git-based version control for infrastructure
- Continuous deployment automation

---

### Bonus: Monitoring Stack
**Goal**: Observe cluster health with Prometheus & Grafana

- Creates **1 VM**: HAMEUR-BONUS (2 vCPU, 4GB RAM)
- Installs K3s + Helm
- Deploys kube-prometheus-stack via Helm charts
- Includes: Prometheus, Grafana, AlertManager, node-exporter
- Grafana dashboards pre-configured for cluster metrics
- Access Grafana at http://192.168.56.110:30300 (admin/prom-operator)

**Key Files**:
- `helm-values/prometheus-values.yaml` - Prometheus Helm config
- `helm-values/grafana-values.yaml` - Grafana Helm config
- `helm-values/loki-values.yaml` - Loki (logs) Helm config
- `scripts/install_k3s.sh` - K3s setup with `--tls-san`
- `scripts/install_helm.sh` - Helm installation + repo setup
- `scripts/deploy_monitoring.sh` - Prometheus stack deployment
- `repos.conf` - Helm repository URLs

**What You'll Learn**:
- Prometheus metrics collection
- Grafana dashboard creation
- Helm for templated deployments
- Observability and cluster monitoring
- PromQL query language basics

---

## 🎓 Learning Outcomes

### Part 1
- ✅ Kubernetes architecture (control plane + workers)
- ✅ Node roles and responsibilities
- ✅ kubectl CLI basics
- ✅ Cluster networking fundamentals

### Part 2
- ✅ Kubernetes Deployments, Pods, Services
- ✅ ConfigMaps for configuration management
- ✅ Ingress controllers and routing
- ✅ Service-to-pod networking
- ✅ Multi-app deployments

### Part 3
- ✅ GitOps workflow (Git → Kubernetes)
- ✅ Declarative infrastructure management
- ✅ ArgoCD application syncing
- ✅ Version control for infrastructure
- ✅ Container orchestration in Docker (K3d)

### Bonus
- ✅ Cluster metrics collection (Prometheus)
- ✅ Data visualization (Grafana)
- ✅ Helm package management
- ✅ Monitoring and observability
- ✅ Alert management

---

## 🛠️ Common Commands

```bash
# Vagrant (on host)
vagrant up              # Start VM & provision
vagrant status          # Check status
vagrant ssh             # SSH into vm
vagrant ssh HAMEUR-SW   # SSH into specific VM
vagrant destroy -f      # Delete VMs
vagrant reload          # Restart VMs

# kubectl (on host or inside VM)
k get nodes             # List nodes
k get pods              # List all pods
k get pods -A           # All pods in all namespaces
k get pods -n argocd    # Pods in specific namespace
k describe pod <name>   # Pod details
k logs <pod>            # Pod logs
k logs -f <pod>         # Follow logs
k exec -it <pod> -- sh  # Shell into pod
k apply -f file.yaml    # Deploy config
k delete -f file.yaml   # Delete config
k port-forward svc/<svc> 8080:80  # Forward port

# Check things
k cluster-info          # Cluster endpoint
k get nodes -o wide     # Nodes with IPs
k get pvc               # Persistent volumes
k get events            # Cluster events
k top nodes             # Resource usage
```

---

## ⚙️ KUBECONFIG & Alias Setup

### For each part, set KUBECONFIG:

```bash
# Part 1 - has output/ subdirectory
export KUBECONFIG=$(pwd)/p1/output/k3s.yaml

# Parts 2, 3, Bonus - kubeconfig in root
export KUBECONFIG=$(pwd)/p2/k3s.yaml    # or p3, bonus
```

### Add alias to ~/.bashrc:

```bash
echo "alias k='kubectl'" >> ~/.bashrc
source ~/.bashrc
```

Inside VMs, alias is already configured by provisioning scripts.

---

## 🔗 Architecture Diagram

```
Part 1: 2-Node Cluster
┌──────────────┐      ┌──────────────┐
│  HAMEUR-S    │      │  HAMEUR-SW   │
│ Control Plane ◄──────►  Worker      │
│  (1 CPU, 1GB) │      │ (1 CPU, 1GB) │
└──────────────┘      └──────────────┘
     ↓ kubeconfig to host

Part 2: Single Node + Apps
┌──────────────────────────────────┐
│      HAMEUR-S                    │
│  K3s + Traefik Ingress          │
│  ├─ app1 (nginx)                │
│  ├─ app2 (nginx)                │
│  └─ app3 (nginx)                │
│  (1 CPU, 1GB)                   │
└──────────────────────────────────┘
    ↓ apps via http://192.168.56.110

Part 3: K3d Docker Cluster + ArgoCD
┌──────────────────────────────────┐
│      HAMEUR-P3                   │
│  K3d in Docker (3 nodes)         │
│  ├─ argocd namespace             │
│  │  └──argo-cd deployment        │
│  └─ app namespace                │
│     └─ webapp (auto-synced)      │
│  (2 CPU, 4GB)                    │
└──────────────────────────────────┘
  ↓ Git controls via ArgoCD

Bonus: Monitoring
┌──────────────────────────────────┐
│      HAMEUR-BONUS                │
│  K3s + Prometheus Stack          │
│  ├─ prometheus (metrics)         │
│  ├─ grafana (dashboards)         │
│  ├─ alertmanager                 │
│  └─ node-exporter                │
│  (2 CPU, 4GB)                    │
└──────────────────────────────────┘
  ↓ dashboards at :30300
```

---

## 🔧 Troubleshooting

**kubectl: command not found?**
```bash
# Install kubectl on host
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl && mv kubectl /usr/local/bin/
```

**Can't connect to cluster?**
```bash
# Make sure KUBECONFIG is set
echo $KUBECONFIG

# If empty, set it:
export KUBECONFIG=$(pwd)/p1/output/k3s.yaml

# Test
k cluster-info
k get nodes
```

**SSL certificate error on host?**
```bash
# This means kubeconfig points to localhost (old issue)
# Fixed by --tls-san flag which includes SERVER_IP
# Solution: Reprovision VM
cd p1
vagrant destroy -f
vagrant up
```

**SSL certificate error inside VM?**
```bash
# Restart VM
vagrant ssh
exit
vagrant reload

# Or SSH into VM and check:
vagrant ssh
k get nodes  # Should work now
```

**Pods won't start?**
```bash
# Check status
k describe pod <pod-name>
k logs <pod-name>

# Check resources
k top nodes

# Check events
k get events
```

**Port forwarding not working?**
```bash
# Verify service exists
k get svc

# Test port forward
k port-forward svc/app1 8080:80

# Open another terminal and test
curl http://localhost:8080
```

---

## 📁 Project Structure

```
IOT/
├── README.md                # This file
│
├── p1/                      # Part 1: K3s Cluster (2 nodes)
│   ├── Vagrantfile         # VMs: HAMEUR-S (server), HAMEUR-SW (worker)
│   ├── ips.conf            # SERVER_IP=192.168.56.110, WORKER_IP=192.168.56.111
│   ├── scripts/
│   │   ├── install_k3s_server.sh    # K3s server with --tls-san
│   │   └── install_k3s_worker.sh    # K3s agent join
│   └── output/             # Generated: k3s.yaml, node-token, server_key.pub
│
├── p2/                      # Part 2: Apps + Ingress (1 node)
│   ├── Vagrantfile         # VM: HAMEUR-S
│   ├── ips.conf            # SERVER_IP=192.168.56.110
│   ├── app1.yaml           # ConfigMap + Deployment (nginx)
│   ├── app2.yaml           # ConfigMap + Deployment (nginx)
│   ├── app3.yaml           # ConfigMap + Deployment (nginx)
│   ├── ingress.yaml        # Traefik Ingress rules
│   ├── scripts/
│   │   └── install_k3s.sh   # K3s + auto-deploy apps
│   └── k3s.yaml            # Generated: kubeconfig
│
├── p3/                      # Part 3: GitOps + ArgoCD
│   ├── Vagrantfile         # VM: HAMEUR-P3 (K3d cluster)
│   ├── ips.conf            # SERVER_IP=192.168.56.110
│   ├── confs/
│   │   ├── deployment.yaml      # App deployment
│   │   ├── service.yaml         # App service
│   │   ├── ingress.yaml         # Ingress rules
│   │   └── argocd-app.yaml      # ArgoCD Application CRD
│   ├── scripts/
│   │   ├── install_tools.sh            # Docker, kubectl, k3d, argocd CLI
│   │   ├── setup_k3d_cluster.sh        # K3d cluster creation
│   │   ├── setup_argocd.sh             # ArgoCD namespace & installation
│   │   ├── deploy_app.sh               # Deploy initial app
│   │   └── setup_portforward.sh        # Pod networking
│   ├── webapp/              # Source app code
│   └── k3s.yaml            # Generated: kubeconfig for K3d
│
└── bonus/                   # Bonus: Monitoring Stack
    ├── Vagrantfile         # VM: HAMEUR-BONUS
    ├── ips.conf            # SERVER_IP=192.168.56.120
    ├── repos.conf          # Helm repository URLs
    ├── helm-values/
    │   ├── prometheus-values.yaml   # Prometheus config
    │   ├── grafana-values.yaml      # Grafana config
    │   └── loki-values.yaml         # Loki (logs) config
    ├── scripts/
    │   ├── install_k3s.sh        # K3s with --tls-san
    │   ├── install_helm.sh       # Helm + repo setup
    │   └── deploy_monitoring.sh  # kube-prometheus-stack deployment
    └── k3s.yaml            # Generated: kubeconfig
```

---

## 📊 Resource Requirements

| Part | RAM | CPU | Disk | Time |
|------|-----|-----|------|------|
| p1 (2 nodes) | 2GB | 2 | 15GB | 15-30m |
| p2 (1 node) | 1GB | 1 | 8GB | 20-40m |
| p3 (K3d) | 4GB | 2 | 10GB | 30-60m |
| bonus | 4GB | 2 | 10GB | 30-50m |
| **Total (all)** | **8GB min** | **4**| **30GB** | **2-3 hours** |

---

## 🚀 Next Steps After Completing

1. **Explore**: Check ArgoCD UI, Grafana dashboards, Prometheus queries
2. **Experiment**: Modify app deployments, add new apps via Git (Part 3)
3. **Extend**: Add networking policies, resource limits, custom monitoring
4. **Learn**: Study Kubernetes docs, try service mesh (Istio), serverless (Knative)
5. **Deploy**: Set up a managed Kubernetes cluster (EKS, GKE, AKS) with same setup

---

## 🤝 Tips

- ✅ Run `vagrant status` to check VM state
- ✅ Use `k logs -f <pod>` to watch live logs
- ✅ Use `k exec -it <pod> -- sh` to debug
- ✅ Inside VMs, `k` alias is auto-configured
- ✅ Check `/etc/rancher/k3s/k3s.yaml` for K3s kubeconfig location
- ✅ Use `k get events` to diagnose issues
- ✅ All VMs have ansible/vagrant user → no password prompt

---

**Start with Part 1, master cluster fundamentals, then progress through the parts. Each is independent but builds on previous knowledge.** 🎉

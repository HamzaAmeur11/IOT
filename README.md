# 🚀 IoT - Inception of Things

Welcome to **Inception of Things** — a comprehensive, hands-on Kubernetes learning project that progressively introduces you to container orchestration, GitOps, and observability. This project is designed to take you from complete beginner to understanding modern DevOps practices.

## 🎯 Project Structure

This project is organized as a **learning journey** with four progressive stages:

| # | Part | Focus | Difficulty | Time |
|---|------|-------|------------|------|
| **1** | [K3s Cluster Setup](#part-1--k3s-cluster-setup) | Multi-node Kubernetes cluster | ⭐⭐ | 15-30m |
| **2** | [Application Deployment](#part-2--application-deployment-with-ingress) | Ingress routing & services | ⭐⭐⭐ | 20-40m |
| **3** | [GitOps with ArgoCD](#part-3--gitops-with-argocd) | Continuous deployment | ⭐⭐⭐⭐ | 30-60m |
| **Bonus** | [Advanced Monitoring](#bonus--advanced-monitoring) | Prometheus & Grafana | ⭐⭐⭐⭐⭐ | 30-50m |

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│           IoT Project Architecture                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Part 1: Cluster Setup                                  │
│  ┌──────────────────┐      ┌──────────────────┐        │
│  │  HAMEUR-S        │  ←→  │ HAMEUR-SW        │        │
│  │ (Control Plane)  │      │ (Worker Node)    │        │
│  └──────────────────┘      └──────────────────┘        │
│                                                           │
│  Part 2: Applications                                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐        │
│  │   app1     │  │   app2     │  │   app3     │        │
│  │  (nginx)   │  │  (nginx)   │  │  (nginx)   │        │
│  └────────────┘  └────────────┘  └────────────┘        │
│        ↑               ↑                ↑                │
│        └───────────────┼────────────────┘               │
│                        │                                 │
│            Traefik Ingress Controller                   │
│                                                           │
│  Part 3: GitOps                                         │
│  ┌──────────────────────────────────────┐              │
│  │         ArgoCD Controller             │              │
│  │  Watches GitHub → Auto-deploys       │              │
│  └──────────────────────────────────────┘              │
│                                                           │
│  Bonus: Monitoring                                      │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │ Prometheus   │  │  Grafana     │                    │
│  │  (Metrics)   │  │  (Dashboard) │                    │
│  └──────────────┘  └──────────────┘                    │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites

### System Requirements

- **Processor**: Multi-core CPU (4+ cores recommended)
- **RAM**: 8GB minimum (12GB+ recommended)
  - Part 1-2: ~2.5GB
  - Part 3: ~2GB
  - Bonus: ~4GB
- **Disk**: 20GB free space
- **OS**: Linux, macOS, or Windows (WSL2)

### Required Software

| Tool | Purpose | Installation |
|------|---------|--------------|
| **VirtualBox** | VM hypervisor | [Download](https://virtualbox.org/) |
| **Vagrant** | VM provisioning (2.0+) | [Download](https://vagrantup.com/) |
| **kubectl** | Kubernetes CLI | `brew install kubectl` (Mac) or see [docs](https://k8s.io/) |
| **Docker** | Container runtime (for Part 3) | [Download](https://docker.com/) |
| **Git** | Version control | [Download](https://git-scm.com/) |

### Optional But Recommended

- **Helm**: Package manager for Kubernetes
- **curl**: For testing endpoints
- **jq**: JSON processor for debugging

---

## 🚀 Quick Start Guide

### All 4 Parts (Complete Journey)

```bash
# Part 1: Cluster Setup (15-30 min)
cd p1
vagrant up                              # Start cluster
export KUBECONFIG=$(pwd)/k3s.yaml
kubectl get nodes                       # Verify
# See p1/README.md for testing

# Part 2: Deploy Applications (20-40 min)
cd ../p2
vagrant up                              # Start single-node cluster
kubectl apply -f app1.yaml              # Deploy apps
kubectl apply -f app2.yaml
kubectl apply -f app3.yaml
kubectl apply -f ingress.yaml
curl http://192.168.56.110              # Test
# See p2/README.md for testing

# Part 3: GitOps with ArgoCD (30-60 min)
cd ../p3
bash scripts/build_versions.sh YOUR_USERNAME
vagrant up
vagrant ssh
sudo bash /vagrant/scripts/setup_k3d_cluster.sh
sudo bash /vagrant/scripts/setup_argocd.sh
sudo bash /vagrant/scripts/deploy_app.sh
# See p3/README.md for testing

# Bonus: Monitoring (30-50 min)
cd ../bonus
vagrant up                              # Starts with Helm monitoring stack
# See bonus/README.md for testing
```

### Individual Parts

Each part is **independent** — you can run any of them directly:

```bash
# Just run Part 2
cd p2
vagrant up

# Just run the Bonus
cd bonus
vagrant up
```

---

## 📖 Part Descriptions

### Part 1: 🔧 K3s Cluster Setup

**Objective**: Set up a functional Kubernetes cluster with multiple nodes

**What you'll learn**:
- K3s lightweight Kubernetes distribution
- Server/worker node architecture
- Node communication and networking
- Kubernetes cluster fundamentals
- kubectl basics

**Setup**: Creates 2 VMs
- `HAMEUR-S` (Control Plane): 192.168.56.110, 1GB RAM
- `HAMEUR-SW` (Worker Node): 192.168.56.111, 1GB RAM

**Testing**: 10+ comprehensive tests including node verification, pod deployment, cluster communication

**[→ Full Part 1 Guide](p1/README.md)**

---

### Part 2: 🌐 Application Deployment with Ingress

**Objective**: Deploy multiple applications and learn routing

**What you'll learn**:
- Kubernetes Deployments and Pods
- ConfigMaps for configuration management
- Services (ClusterIP) for internal networking
- Ingress for external HTTP routing
- Traefik ingress controller
- Virtual hosting (host-based routing)

**Setup**: Single-node K3s cluster
- `HAMEUR-S`: 192.168.56.110, 1GB RAM

**Deploys**: 3 sample nginx applications with HTML content

**Testing**: 10 comprehensive tests covering deployment, services, ingress routing, and endpoint access

**[→ Full Part 2 Guide](p2/README.md)**

---

### Part 3: 🔄 GitOps with ArgoCD

**Objective**: Implement GitOps for continuous deployment

**What you'll learn**:
- GitOps principles and philosophy
- ArgoCD for continuous deployment
- Git as single source of truth
- Automated synchronization
- Self-healing deployments
- Version upgrades via Git
- CI/CD pipeline integration

**Setup**: K3d cluster with ArgoCD
- `HAMEUR-BONUS`: 192.168.56.110, 4GB RAM
- Requires GitHub repository setup

**Deploys**: Sample application with v1 and v2 versions

**Testing**: 10 comprehensive tests including ArgoCD UI access, GitOps workflow testing, auto-healing verification

**[→ Full Part 3 Guide](p3/README.md)**

---

### Bonus: 📊 Advanced Monitoring

**Objective**: Set up production-grade monitoring with Prometheus & Grafana

**What you'll learn**:
- Prometheus for metrics collection
- Grafana for visualization
- Helm for templated deployments
- Custom dashboards
- Metric queries (PromQL)
- Observability best practices

**Setup**: K3s with Helm-deployed monitoring stack
- `HAMEUR-BONUS`: 192.168.56.110, 4GB RAM, 2 CPUs

**Deploys**: Full kube-prometheus-stack via Helm

**Testing**: 10 comprehensive tests for monitoring components, dashboards, metrics collection

**[→ Full Bonus Guide](bonus/README.md)**

---

## 🧪 Testing Your Setup

Each part includes comprehensive test suites to verify everything works:

### Quick Health Checks

```bash
# Part 1: Verify cluster operational
cd p1
export KUBECONFIG=$(pwd)/k3s.yaml
kubectl get nodes                       # Both nodes Ready?
kubectl get pods -A                     # System pods running?

# Part 2: Verify applications deployed
cd p2
kubectl get deployments                 # All 3 deployed?
kubectl get ingress                     # Ingress configured?
curl http://app1.com                    # Can route traffic?

# Part 3: Verify GitOps working
cd p3
kubectl get application -n argocd       # ArgoCD app synced?
curl http://192.168.56.110:30081/       # Application responding?

# Bonus: Verify monitoring
cd bonus
kubectl get pods -n prometheus          # Prometheus running?
# Visit http://192.168.56.110:30300     # Grafana dashboard
```

### Comprehensive Test Scripts

Each part has full test scripts:

```bash
cd p1 && bash test_p1.sh
cd p2 && bash test_p2.sh
cd p3 && bash test_p3_gitops.sh
cd bonus && bash test_bonus.sh
```

---

## 🎓 Learning Path

### Knowledge Progression

```
Beginner
  ↓
Part 1: "How does Kubernetes work?"
  ↓
Part 2: "How do I run apps in Kubernetes?"
  ↓
Intermediate
  ↓
Part 3: "How do I automate deployments?"
  ↓
Bonus: "How do I monitor production systems?"
  ↓
Advanced
```

### Recommended Approach

1. **Start with Part 1**: Understand the fundamentals
2. **Move to Part 2**: Learn practical deployment
3. **Continue to Part 3**: Understand modern DevOps
4. **Optional Bonus**: Dive into observability

Each part builds on previous knowledge but can run independently.

---

## 🛠️ Common Operations

### Vagrant Commands

```bash
vagrant up              # Start VM(s) and provision
vagrant status          # Check VM status
vagrant ssh             # SSH into primary VM
vagrant ssh <name>      # SSH into specific VM
vagrant halt            # Stop VM(s) gracefully
vagrant reload          # Restart VM(s)
vagrant destroy -f      # Delete VM(s) and data
vagrant provision       # Re-run provisioning scripts
```

### Kubernetes Commands

```bash
# Cluster Info
kubectl get nodes                       # List nodes
kubectl cluster-info                    # Cluster details
kubectl describe node <node>            # Node details

# Pods & Deployments
kubectl get pods                        # List pods
kubectl get deployments                 # List deployments
kubectl describe pod <pod>              # Pod details
kubectl logs <pod>                      # Pod logs
kubectl exec -it <pod> -- /bin/sh       # Shell into pod

# Services & Ingress
kubectl get svc                         # List services
kubectl get ingress                     # List ingress rules
kubectl describe ingress <name>         # Ingress details

# Namespaces
kubectl get namespaces                  # List namespaces
kubectl get pods -n <namespace>         # Pods in namespace
kubectl create namespace <name>         # Create namespace

# Debugging
kubectl get events                      # Recent events
kubectl top nodes                       # Node resource usage
kubectl get pvc                         # Persistent volumes
```

### Port Forwarding (Access Services)

```bash
# Access service from host
kubectl port-forward svc/app1 8080:80

# Access pod from host
kubectl port-forward pod/app1-xxxx 8080:80

# Access on specific interface
kubectl port-forward --address 192.168.1.10 svc/app1 8080:80
```

---

## 🐛 Troubleshooting

### Can't connect to cluster

```bash
# Check if VMs running
vagrant status

# Fix kubeconfig
export KUBECONFIG=$(pwd)/k3s.yaml

# Test connectivity
kubectl cluster-info

# SSH into VM and check K3s
vagrant ssh
sudo systemctl status k3s           # Server
sudo systemctl status k3s-agent     # Worker/Agent
```

### Pods won't start

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check pod logs
kubectl logs <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check resource availability
kubectl top nodes
kubectl describe node <node>
```

### Network issues

```bash
# Check service endpoints
kubectl get endpoints

# Check network policies
kubectl get networkpolicies

# Test DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside pod: nslookup kubernetes
```

### VM Issues

```bash
# Check VirtualBox
VBoxManage list runningvms

# Enable nested virtualization (if needed)
VBoxManage modifyvm <name> --nested-hw-virt on

# Check logs
vagrant up --debug

# Clean restart
vagrant destroy -f
vagrant up
```

---

## 📚 Learning Resources

### Official Documentation

- [Kubernetes Docs](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Concepts & Theory

- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [GitOps Principles](https://gitops.tech/)
- [Prometheus Metrics](https://prometheus.io/docs/concepts/metric_types/)

### Practice & Tutorials

- [Kubernetes by Example](https://kubernetesbyexample.com/)
- [Interactive Kubernetes Tutorial](https://www.katacoda.com/courses/kubernetes)
- [K3s Quick Start](https://docs.k3s.io/quick-start)

---

## 💾 File Structure

```
IOT/
├── README.md                    # Main documentation (this file)
│
├── p1/                          # Part 1: K3s Cluster
│   ├── README.md               # Part 1 guide with tests
│   ├── Vagrantfile
│   ├── ips.conf
│   ├── scripts/
│   │   ├── install_k3s_server.sh
│   │   └── install_k3s_worker.sh
│   └── output/                 # Generated (kubeconfig, tokens)
│
├── p2/                          # Part 2: Ingress & Apps
│   ├── README.md               # Part 2 guide with tests
│   ├── Vagrantfile
│   ├── ips.conf
│   ├── app1.yaml               # App deployments
│   ├── app2.yaml
│   ├── app3.yaml
│   ├── ingress.yaml
│   ├── scripts/
│   └── output/
│
├── p3/                          # Part 3: GitOps
│   ├── README.md               # Part 3 guide with tests
│   ├── Vagrantfile
│   ├── ips.conf
│   ├── confs/                  # Kubernetes configs
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── argocd-app.yaml
│   ├── scripts/
│   ├── webapp/                 # Source code
│   └── output/
│
└── bonus/                       # Bonus: Monitoring
    ├── README.md               # Bonus guide with tests
    ├── Vagrantfile
    ├── ips.conf
    ├── helm-values/            # Helm chart values
    │   ├── prometheus-values.yaml
    │   ├── grafana-values.yaml
    │   └── loki-values.yaml
    ├── scripts/
    └── output/
```

---

## 🔄 Cleanup & Disk Management

### Clean up one part

```bash
cd p1          # or p2, p3, bonus
vagrant destroy -f
```

### Clean up completely

```bash
# Remove all VMs from all parts
cd p1 && vagrant destroy -f
cd ../p2 && vagrant destroy -f
cd ../p3 && vagrant destroy -f
cd ../bonus && vagrant destroy -f

# Check remaining VMs
VBoxManage list runningvms
VBoxManage list vms
```

### Reclaim disk space

```bash
# Remove all VirtualBox data
rm -rf ~/VirtualBox*

# Or per VM
VBoxManage unregistervm <vm-name> --delete
```

---

## 🎯 Progression Checkpoints

### Completed Part 1?
- ✅ Can run `kubectl get nodes` and see 2 Ready nodes
- ✅ Can deploy and access a test pod
- ✅ Understand K3s architecture

**Next**: Move to Part 2

### Completed Part 2?
- ✅ Can deploy multiple applications
- ✅ Can access apps via Ingress
- ✅ Understand ConfigMaps and Services

**Next**: Move to Part 3

### Completed Part 3?
- ✅ Can access ArgoCD UI
- ✅ Can upgrade application via Git
- ✅ Understand GitOps workflow

**Next**: Try Bonus or explore service mesh/serverless

### Completed Bonus?
- ✅ Can access Prometheus and Grafana
- ✅ Can query Prometheus metrics
- ✅ Understand monitoring and observability

**Next**: Production-grade deployment, multi-cluster, compliance

---

## 🤝 Tips for Success

### Best Practices

1. **Read each part's README fully** before starting
2. **Run tests after setup** to verify everything works
3. **Don't skip troubleshooting** — it's part of learning
4. **Use port-forward for local access** — simpler than SSH
5. **Check logs when things fail** — most info is there

### Common Mistakes

❌ Not using `export KUBECONFIG` — hard to access cluster
❌ Forgetting to add `/etc/hosts` entries in Part 2
❌ Trying Part 3 without GitHub setup
❌ Destroying VMs mid-provisioning — wait for completion
❌ Running multiple `vagrant up` in same directory

### Pro Tips

✅ Use aliases: `alias k=kubectl`
✅ Watch pod logs: `kubectl logs -f <pod>`
✅ Use `-A` flag often: `kubectl get pods -A`
✅ Port-forward background: `kubectl port-forward ... &`
✅ Use `--dry-run=client -o yaml` to preview changes

---

## 🎓 What You'll Learn

### Foundational Knowledge
- ✅ Container orchestration basics
- ✅ Kubernetes architecture and components
- ✅ Pod, deployment, and service concepts
- ✅ Ingress and routing

### Practical Skills
- ✅ Deploy applications on Kubernetes
- ✅ Manage configuration with ConfigMaps
- ✅ Set up and troubleshoot networking
- ✅ Use kubectl effectively

### Advanced Concepts
- ✅ GitOps and declarative workflows
- ✅ Continuous deployment with ArgoCD
- ✅ Monitoring and observability
- ✅ Production deployment patterns

### Real-World Experience
- ✅ Multi-node cluster management
- ✅ Application versioning and upgrades
- ✅ Metrics collection and dashboards
- ✅ Troubleshooting and debugging

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| Total Setup Time | ~2-3 hours |
| Parts | 4 (3 core + 1 bonus) |
| VMs Created | Up to 8 (2 per part) |
| Kubernetes Namespaces | 10+ |
| Applications Deployed | 6+ |
| Testing Scenarios | 40+ |
| Docker Images | 5+ |
| Helm Charts | 1+ |

---

## ⭐ Next Steps After Completing IoT

### Extend Your Knowledge

1. **Service Mesh**: Add Istio/Linkerd for advanced routing
2. **Serverless**: Explore Knative for functions
3. **GitOps Advanced**: Multi-cluster, multi-environment
4. **Security**: RBAC, network policies, pod security
5. **Storage**: StatefulSets, databases, persistent volumes

### Production Deployment

1. Set up managed Kubernetes (EKS, GKE, AKS)
2. Implement CI/CD pipeline (GitHub Actions, GitLab CI)
3. Add observability (ELK, Jaeger, Prometheus)
4. Set up security scanning and compliance
5. Plan disaster recovery and backups

### Community & Learning

- Join Kubernetes communities
- Contribute to open-source projects
- Get certified (CKA, CKE exams)
- Share your knowledge with others

---

## 📝 Project Completion Checklist

- [ ] **Part 1**: Both nodes Ready, cluster operational
- [ ] **Part 1**: Can deploy and access test pod
- [ ] **Part 2**: All 3 apps deployed and accessible
- [ ] **Part 2**: Ingress routing working (app1.com, app2.com)
- [ ] **Part 3**: ArgoCD installed and accessible
- [ ] **Part 3**: GitOps workflow tested (v1 → v2)
- [ ] **Bonus**: Prometheus collecting metrics
- [ ] **Bonus**: Grafana dashboards displaying data
- [ ] **All**: Can run tests and understand output
- [ ] **All**: Can troubleshoot common issues

---

## 🤗 Feedback & Support

This project is designed for learning. If you:
- Get stuck on a part
- Find unclear documentation
- Discover issues with scripts
- Have suggestions for improvement

**Check the README for that specific part** — it has:
- Detailed setup instructions
- 10+ comprehensive tests
- Troubleshooting section
- Common issues and solutions

---

## 🎉 Acknowledgments

This project is inspired by the 42 School's IoT assignment and combines modern Kubernetes and DevOps best practices.

---

## 📄 License

This project is for educational purposes.

---

## 🏁 Ready to Start?

1. Choose your part: **[Part 1](p1/README.md)** | **[Part 2](p2/README.md)** | **[Part 3](p3/README.md)** | **[Bonus](bonus/README.md)**
2. Read the part's README thoroughly
3. Follow setup instructions
4. Run the test suite
5. Troubleshoot any issues
6. Celebrate your success! 🎊

---

**Welcome to the IoT Learning Journey!** 🚀

*Happy Kubernetes Learning!*
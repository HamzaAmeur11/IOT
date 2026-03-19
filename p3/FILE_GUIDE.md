# 📍 P3 File Navigation Guide

## Quick Navigation

**Just want to get started?**
→ Open and read: `START_HERE.md` then `EXECUTION_GUIDE.md`

**Need a specific command?**
→ Open: `CHEATSHEET.md`

**Want to understand concepts?**
→ Open: `SETUP_GUIDE.md`

**Something broken?**
→ Check: `CHEATSHEET.md` (Troubleshooting section)

---

## 📄 All Documentation Files

### 🌟 **START_HERE.md** (Your Entry Point)
**Purpose**: Master guide with roadmap and quick start  
**Read when**: First thing, before anything else  
**Contains**: 
- Documentation reading order
- Pre-requisites
- Project structure
- Success criteria
- Learning paths (fast vs detailed)

**How long**: 10-15 minutes

---

### 📖 **SETUP_GUIDE.md** (Learn Concepts)
**Purpose**: Deep dive into concepts and detailed commands  
**Read when**: During Phase 1 (Learning)  
**Contains**:
- Part 0: Concept explanations (K3d vs K3s vs K3c, ArgoCD, Docker Hub)
- Part 1: Installation commands (k3d, kubectl, helm)
- Part 2: ArgoCD installation & access
- Part 3: Application setup (Docker image)
- Part 4: ArgoCD application manifests
- Part 5: Deployment verification
- Part 6: Version testing
- Troubleshooting tips

**How long**: 30-45 minutes (reference material)

---

### ✅ **EXECUTION_GUIDE.md** (Your Main Checklist)
**Purpose**: Practical step-by-step tasks with exact commands  
**Read when**: During Phases 2-6 (Main implementation)  
**Contains**:
- Phase 1: Learning & Understanding (resources)
- Phase 2: GitHub Repository Setup (exact commands)
- Phase 3: Docker Hub (build & push v1/v2)
- Phase 4: Deploy Everything (Vagrant setup)
- Phase 5: Test GitOps (version change demo)
- Phase 6: Verification (screenshots)
- Common issues & solutions
- Deliverables checklist
- Time estimations for each phase

**How long**: 2-2.5 hours (actual execution time)

---

### ⚡ **CHEATSHEET.md** (Quick Reference)
**Purpose**: Common commands and quick fixes  
**Read when**: While working (keep it open in another terminal/editor)  
**Contains**:
- VM management commands
- Kubernetes commands
- Docker commands
- ArgoCD commands
- Git commands
- Testing commands
- Debugging & troubleshooting
- K3d cluster management
- File locations in VM
- Quick workflow example
- Useful tips

**How long**: Reference only (30 seconds to 2 minutes per lookup)

---

### 📋 **SUMMARY.md** (This Project's Overview)
**Purpose**: High-level summary of the entire setup  
**Read when**: After START_HERE.md for context  
**Contains**:
- What was created for you
- What was already ready
- Your next steps (in order)
- Key information table
- What you'll create
- Expected outputs
- Time breakdown
- Quick checklist

**How long**: 5-10 minutes

---

## 🔧 Script Files

### **scripts/install_tools.sh**
**Purpose**: Install Docker, kubectl, k3d, ArgoCD CLI  
**When used**: Automatically during `vagrant up`  
**Do you edit it?**: No, it's automatic  
**Manual run**: 
```bash
vagrant ssh
bash /vagrant/scripts/install_tools.sh
```

---

### **scripts/setup_k3d_cluster.sh**
**Purpose**: Create k3d cluster with 1 server + 2 agents  
**When used**: Automatically during `vagrant up`  
**Manual run**: 
```bash
vagrant ssh
bash /vagrant/scripts/setup_k3d_cluster.sh
```

---

### **scripts/setup_argocd.sh**
**Purpose**: Install ArgoCD in cluster  
**When used**: Automatically during `vagrant up`  
**Saves**: ArgoCD password to `/vagrant/argocd-password.txt`  
**Manual run**: 
```bash
vagrant ssh
bash /vagrant/scripts/setup_argocd.sh
```

---

### **scripts/deploy_app.sh**
**Purpose**: Deploy initial application (playground)  
**When used**: Automatically during `vagrant up`  
**Manual run**: 
```bash
vagrant ssh
bash /vagrant/scripts/deploy_app.sh
```

---

### **scripts/build_versions.sh** ✨ (NEW!)
**Purpose**: Helper to build and push v1/v2 images to Docker Hub  
**Usage**:
```bash
./scripts/build_versions.sh YOUR-USERNAME v1
./scripts/build_versions.sh YOUR-USERNAME v2
```
**Install**: 
```bash
chmod +x scripts/build_versions.sh
```

---

## 🐳 Kubernetes Manifest Files

### **confs/deployment.yaml**
**Purpose**: Define how your app runs  
**Contains**: Container image, ports, resource limits  
**Edit when**: Changing app version or image  

Example:
```yaml
image: wil42/playground:latest  # Change this to your image
```

---

### **confs/service.yaml**
**Purpose**: How to access your app  
**Contains**: Port mapping, service type  
**Default**: LoadBalancer on port 8888  

---

### **confs/ingress.yaml**
**Purpose**: URL routing (optional)  
**Status**: Usually not needed for this project  
**Use only if**: You need domain-based routing

---

### **confs/argocd-app.yaml**
**Purpose**: Tells ArgoCD what to deploy  
**Contains**: GitHub repo URL, target namespace  
**Edit when**: Setting up your own manifests repo  

Example:
```yaml
repoURL: https://github.com/YOUR-USERNAME/YOUR-USERNAME-iot-manifests.git
```

---

## 🐍 Application Files

### **webapp/app.py**
**Purpose**: Flask application with versioning  
**Features**:
- `/` endpoint returns JSON with version
- `/health` endpoint for health checks
- Reads version from environment variable

---

### **webapp/Dockerfile**
**Purpose**: Define how to containerize the app  
**Contains**: Python image, dependencies, port 8888  
**Version set**: `ENV APP_VERSION=v1`

---

### **webapp/requirements.txt**
**Purpose**: Python package dependencies  
**Contains**: Flask and werkzeug versions

---

### **webapp/docker-compose.yml**
**Purpose**: Local testing without building Docker image  
**Usage**: `docker-compose up` for quick testing

---

### **webapp/README.md**
**Purpose**: Flask app documentation  

---

## ⚙️ Configuration Files

### **Vagrantfile**
**Purpose**: VM configuration  
**Contains**:
- VM specs (4GB RAM, 2 CPUs)
- Port forwarding (8080, 8888, 6443)
- IP configuration
- Provisioning script calls

**Edit if**: Changing ports or VM specs

---

### **ips.conf**
**Purpose**: Network configuration  
**Contains**: SERVER_IP=192.168.56.110  
**Edit if**: Changing VM IP address

---

## 📚 Optional/Reference Documentation

### **README.md** (Original)
**Purpose**: Project overview (already existed)  
**Status**: Still valid, shows Vagrant quick start

---

### **GITHUB_SETUP.md** (Original)
**Purpose**: Using GitHub Container Registry (optional)  
**Status**: Alternative approach with GitHub Actions  
**Use only if**: You want CI/CD with GitHub Actions building images

---

### **WEBAPP_SETUP.md** (Original)
**Purpose**: Detailed app building guide (optional)  
**Status**: Covered in EXECUTION_GUIDE Phase 3  
**Use only if**: You want more detail on Docker builds

---

## 🗺️ File Organization Diagram

```
p3/
│
├── 📖 Documentation (READ THESE FIRST)
│   ├── START_HERE.md ⭐ Start Here!
│   ├── SUMMARY.md (Overview)
│   ├── SETUP_GUIDE.md (Concepts)
│   ├── EXECUTION_GUIDE.md (Main Checklist)
│   ├── CHEATSHEET.md (Quick Ref)
│   ├── README.md (Original Overview)
│   ├── GITHUB_SETUP.md (Optional)
│   └── WEBAPP_SETUP.md (Optional)
│
├── ⚙️ Configuration
│   ├── Vagrantfile (VM config)
│   └── ips.conf (Network config)
│
├── 🔧 Scripts
│   └── scripts/
│       ├── install_tools.sh
│       ├── setup_k3d_cluster.sh
│       ├── setup_argocd.sh
│       ├── deploy_app.sh
│       └── build_versions.sh ✨ (NEW!)
│
├── 🐳 Kubernetes Manifests
│   └── confs/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── argocd-app.yaml
│
└── 🐍 Application
    └── webapp/
        ├── app.py
        ├── Dockerfile
        ├── requirements.txt
        ├── docker-compose.yml
        └── README.md
```

---

## 🎯 Reading Paths

### Fast Track (Want to just get it working)
```
1. START_HERE.md (5 min)
   ↓
2. EXECUTION_GUIDE.md Phase 1 (30 min - just the learning resources)
   ↓
3. EXECUTION_GUIDE.md Phases 2-6 (follow exactly)
   ↓
4. Keep CHEATSHEET.md open for commands
```

### Thorough Track (Want to understand everything)
```
1. START_HERE.md (10 min)
   ↓
2. SETUP_GUIDE.md Part 0 (Concepts explanation - 30 min)
   ↓
3. Watch Rancher video (20 min)
   ↓
4. Read ArgoCD docs (15 min)
   ↓
5. EXECUTION_GUIDE.md Phases 2-6
   ↓
6. Refer to CHEATSHEET.md and SETUP_GUIDE.md as needed
```

### Reference-Only Track (Just need commands)
```
Keep open:
- CHEATSHEET.md (for any command you need)
- EXECUTION_GUIDE.md (specific phases as you go)
```

---

## ✅ How to Know Which File to Use

| I need to... | Use this file |
|-------------|---------------|
| Get started quickly | START_HERE.md |
| Understand K3d vs K3s | SETUP_GUIDE.md (Part 0) |
| Understand ArgoCD | SETUP_GUIDE.md (Part 0) |
| Get exact commands | EXECUTION_GUIDE.md or CHEATSHEET.md |
| Quick kubectl command | CHEATSHEET.md |
| Troubleshoot problem | CHEATSHEET.md (Troubleshooting section) |
| Understand GitOps | SETUP_GUIDE.md (Part 0) |
| Learn Docker Hub role | SETUP_GUIDE.md (Part 0) |
| Build Docker images | EXECUTION_GUIDE.md Phase 3 or scripts/build_versions.sh |
| Setup GitHub repo | EXECUTION_GUIDE.md Phase 2 |
| Deploy application | EXECUTION_GUIDE.md Phase 4 |
| Test version change | EXECUTION_GUIDE.md Phase 5 |
| See file locations | CHEATSHEET.md (File Locations section) |

---

## 🚀 Where to Start Right Now

**Read this first**: [START_HERE.md](START_HERE.md)

**Then execute from**: [EXECUTION_GUIDE.md](EXECUTION_GUIDE.md)

**Keep handy**: [CHEATSHEET.md](CHEATSHEET.md)

---

Good luck! 🎉

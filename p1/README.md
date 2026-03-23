# Part 1: K3s Cluster Setup - Server & Worker Nodes

## 📌 Overview

This part sets up a **two-node Kubernetes cluster** using K3s (lightweight Kubernetes distribution). You'll create a control-plane node (server) and a worker node that communicate with each other to form a functional Kubernetes cluster.

### Architecture

```
┌──────────────────────────┐
│     HAMEUR-S (Server)    │  192.168.56.110
│   (Control Plane)        │
│  - API Server            │
│  - Scheduler             │
│  - Controller Manager    │
└────────────┬─────────────┘
             │  (Internal K3s token)
             │  (Flannel networking)
             │
┌────────────▼─────────────┐
│   HAMEUR-SW (Worker)     │  192.168.56.111
│   (Worker Node)          │
│  - kubelet               │
│  - container runtime     │
└──────────────────────────┘
```

### Learning Objectives

- Understand K3s vs full Kubernetes
- Learn how server and worker nodes communicate
- Set up a multi-node cluster from scratch
- Verify cluster health and node status

---

## 🛠️ Prerequisites

- **VirtualBox**: VM hypervisor
- **Vagrant**: VM provisioning tool (v2.0+)
- **kubectl**: Kubernetes CLI (on host, optional)
- **System Resources**:
  - 2.5 GB available RAM (1GB per VM)
  - 10 GB free disk space
  - Network access for downloads

---

## 🚀 Quick Start

```bash
cd p1
vagrant up              # Start both VMs and configure K3s
```

The setup will:
1. Create two Ubuntu 22.04 VMs
2. Install K3s on the server node
3. Join the worker node to the cluster
4. Extract kubeconfig to `k3s.yaml`

**Estimated time**: 5-7 minutes

---

## ✅ Testing & Verification

### Test 1: Verify Nodes Are Ready

```bash
# From host machine
export KUBECONFIG=$(pwd)/k3s.yaml
kubectl get nodes
```

**Expected output**:
```
NAME       STATUS   ROLES                       AGE   VERSION
HAMEUR-S   Ready    control-plane,master        2m    v1.30.x
HAMEUR-SW  Ready    <none>                      1m    v1.30.x
```

✅ **Success**: Both nodes show `Ready` status

### Test 2: Check Node Details

```bash
kubectl describe node HAMEUR-S
kubectl describe node HAMEUR-SW
```

**What to verify**:
- ✅ `Status: Ready`
- ✅ `Role` labels present
- ✅ `Capacity` shows memory and CPU allocation
- ✅ `Allocatable` shows available resources
- ✅ No `NotReady`, `OutOfDisk`, or `MemoryPressure` conditions

### Test 3: Verify Cluster Communication

```bash
# SSH into server and check worker node from within cluster
vagrant ssh HAMEUR-S

# Inside server VM
kubectl get nodes -o wide
sudo systemctl status k3s              # Check K3s service
```

**What to look for**:
- ✅ Both nodes appear in the node list
- ✅ K3s service is `active (running)`
- ✅ No error messages in logs

### Test 4: Check System Pods

```bash
kubectl get pods -A
```

**Expected system pods** (should be Running):
```
NAMESPACE       NAME                                 READY   STATUS    AGE
kube-system     coredns-85b94c62f7-xxx               1/1     Running   2m
kube-system     local-path-provisioner-xxx-xxx       1/1     Running   2m
kube-system     metrics-server-xxx-xxx               1/1     Running   2m
kube-system     traefik-xxx-xxx                      1/1     Running   2m
kube-system     flannel-xxx                          1/1     Running   2m
kube-system     flannel-xxx                          1/1     Running   2m
```

✅ **Success**: All system pods are running

### Test 5: Deploy a Test Pod

```bash
# Deploy nginx pod
kubectl run test-nginx --image=nginx:alpine

# Wait for it to be ready
kubectl wait --for=condition=ready pod test-nginx --timeout=60s

# Check if pod is running
kubectl get pods

# Test connectivity to the pod
kubectl port-forward pod/test-nginx 8080:80 &
sleep 1
curl http://localhost:8080
kill %1
```

**Expected**: Nginx welcome page HTML or "Welcome to nginx!"

✅ **Success**: Pod deployed and accessible

### Test 6: Verify Inter-Node Communication

```bash
# Create a pod on worker node
kubectl run worker-test --image=nginx:alpine --node-selector=kubernetes.io/hostname=HAMEUR-SW

# Verify pod is running on worker
kubectl get pods -o wide
# Should show pod on HAMEUR-SW

# Clean up
kubectl delete pod test-nginx worker-test
```

✅ **Success**: PODs can be scheduled on both nodes

### Test 7: Check API Server Logs

```bash
# View K3s logs
vagrant ssh HAMEUR-S -c "sudo journalctl -u k3s -n 50"
```

**What to look for**:
- ✅ No CRITICAL or ERROR messages
- ✅ Node join messages appear
- ✅ No CrashLoopBackOff messages

---

## 📊 Full Test Suite

Run this comprehensive test from your host machine:

```bash
#!/bin/bash
set -e

echo "=== Part 1: Cluster Setup Tests ==="
export KUBECONFIG=$(pwd)/k3s.yaml

# Test 1: Nodes
echo "✓ Test 1: Nodes Ready"
kubectl wait --for=condition=Ready node --all --timeout=300s
kubectl get nodes

# Test 2: System pods
echo "✓ Test 2: System Pods Running"
kubectl wait --for=condition=ready pod -l component=kubelet -n kube-system --timeout=60s || true
kubectl get pods -n kube-system

# Test 3: API Server
echo "✓ Test 3: API Server Responsive"
kubectl cluster-info

# Test 4: Create namespace
echo "✓ Test 4: Namespace Creation"
kubectl create namespace test || true
kubectl get namespace test

# Test 5: Deploy test pod
echo "✓ Test 5: Pod Deployment"
kubectl run -n test test-pod --image=nginx:alpine
kubectl wait --for=condition=ready pod -n test test-pod --timeout=60s
kubectl get pods -n test

# Test 6: Service creation
echo "✓ Test 6: Service Creation"
kubectl expose pod -n test test-pod --port=80 --name=test-svc
kubectl get svc -n test

# Test 7: Cleanup
echo "✓ Test 7: Resource Cleanup"
kubectl delete namespace test

echo ""
echo "✅ All tests passed!"
```

Save as `test_p1.sh` and run:
```bash
bash test_p1.sh
```

---

## 🔧 Useful Commands

### Cluster Information

```bash
# Get cluster information
kubectl cluster-info

# Get cluster version
kubectl version

# Describe the cluster
kubectl get cs  # component status (deprecated but useful)
```

### Node Management

```bash
# Get nodes with more details
kubectl get nodes -o wide

# Get node resource usage
kubectl top nodes

# Get node events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Cordon a node (prevent scheduling)
kubectl cordon HAMEUR-SW

# Uncordon a node
kubectl uncordon HAMEUR-SW

# Drain a node (move pods off)
kubectl drain HAMEUR-SW --ignore-daemonsets
```

### Pod Management

```bash
# Get all system pods
kubectl get pods -n kube-system

# Check pod logs
kubectl logs -n kube-system pod-name

# Execute command in pod
kubectl exec -it pod-name -- /bin/sh

# Port forward to pod
kubectl port-forward pod-name 8080:80
```

### Debugging

```bash
# SSH into server VM
vagrant ssh HAMEUR-S

# SSH into worker VM
vagrant ssh HAMEUR-SW

# Check K3s status in VM
sudo systemctl status k3s

# Check K3s logs
sudo journalctl -u k3s -f

# Check Docker status (K3s uses containerd)
sudo systemctl status k3s
```

---

## 🐛 Troubleshooting

### Problem: Worker node shows "NotReady"

```bash
# SSH into worker node
vagrant ssh HAMEUR-SW

# Check if K3s agent is running
sudo systemctl status k3s-agent

# Check logs
sudo journalctl -u k3s-agent -n 50

# Restart agent
sudo systemctl restart k3s-agent

# Wait and check
sleep 10 && kubectl get nodes
```

### Problem: Pods won't schedule

```bash
# Check node resources
kubectl describe node HAMEUR-S
kubectl describe node HAMEUR-SW

# Look for "MemoryPressure" or "DiskPressure" conditions

# If low on resources, delete test pods first
kubectl delete pods --all
```

### Problem: Can't connect from host machine

```bash
# Update kubeconfig with correct server IP
sed -i 's/127.0.0.1:6443/192.168.56.110:6443/g' k3s.yaml

# Or set KUBECONFIG
export KUBECONFIG=$(pwd)/k3s.yaml
```

### Problem: VMs won't start

```bash
# Check VirtualBox
VBoxManage list runningvms

# Start with debug output
vagrant up --debug

# Destroy and retry
vagrant destroy -f
vagrant up
```

---

## 📚 Understanding K3s

### What is K3s?

K3s is a **lightweight, production-grade Kubernetes distribution**:
- **Single binary**: ~60MB vs 500MB+ for full Kubernetes
- **Low resource usage**: Runs on 512MB RAM minimum
- **Great for**: Development, testing, edge computing, IoT
- **Drop-in replacement**: Compatible with standard Kubernetes

### Key Components

| Component | Role |
|-----------|------|
| **API Server** | REST API for cluster management |
| **Scheduler** | Assigns pods to nodes |
| **Controller Manager** | Runs cluster controllers |
| **kubelet** | Node agent managing pods |
| **Flannel** | Network plugin (CNI) |
| **Traefik** | Built-in ingress controller |

### How Nodes Join

```
Server Node (HAMEUR-S)
↓
1. K3s starts on server
2. Generates node token
3. Stores token in /var/lib/rancher/k3s/server/node-token
↓
Worker Node (HAMEUR-SW)
↓
1. Reads server URL and token from SSH or shared config
2. Runs K3s agent with --server flag
3. Agent contacts API server
4. Controller manager accepts node registration
5. Worker ready for pod scheduling
```

---

## 📋 Cleanup

To remove all VMs and data:

```bash
vagrant destroy -f
```

This removes:
- ✅ Both VMs
- ✅ All containers and pod data
- ✅ Kubernetes cluster state

**Note**: Generated files like `k3s.yaml` remain in the host directory for reference.

---

## 🎓 Next Steps

Once Part 1 is working:

1. **Part 2**: Deploy applications with Ingress routing
2. **Part 3**: Implement GitOps with ArgoCD
3. **Bonus**: Add monitoring with Prometheus & Grafana

---

## 📖 Further Reading

- [K3s Official Documentation](https://docs.k3s.io/)
- [Kubernetes API Concepts](https://kubernetes.io/docs/concepts/overview/what-is-kubernetes/)
- [Kubernetes Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/)
- [Flannel CNI Plugin](https://github.com/flannel-io/flannel)

---

## ✨ Summary

**Part 1 teaches you**:
- How to set up a multi-node Kubernetes cluster
- Understanding of server/worker node architecture
- K3s as a lightweight Kubernetes alternative
- Basic kubectl commands for cluster verification
- Troubleshooting cluster issues

**Time to complete**: 15-30 minutes (including setup time)

**Difficulty**: ⭐⭐ (Beginner)

---

**Ready to test? Start with Test 1 above!** ✅

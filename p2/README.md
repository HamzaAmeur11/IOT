# Part 2: Application Deployment with Ingress Routing

## 📌 Overview

This part demonstrates how to **deploy multiple containerized applications** on a single K3s server and expose them to the outside world using **Ingress routing**. You'll learn how Traefik (built-in ingress controller) routes HTTP traffic to the correct service based on hostnames and paths.

### Architecture

```
┌──────────────────────────────────────────┐
│         Client Browser/curl              │
│  (192.168.56.110, app1.com, app2.com)   │
└────────────────┬─────────────────────────┘
                 │ HTTP request
                 ▼
┌──────────────────────────────────────────┐
│    Traefik Ingress Controller             │
│    (Port 80)                             │
│  - Host-based routing                    │
│  - Path-based routing                    │
└────────────┬───────────────┬───────────┬─┘
             │               │           │
             ▼               ▼           ▼
        ┌─────────┐    ┌─────────┐  ┌─────────┐
        │  app1   │    │  app2   │  │  app3   │
        │ Service │    │ Service │  │ Service │
        │ (nginx) │    │ (nginx) │  │ (nginx) │
        └────┬────┘    └────┬────┘  └────┬────┘
             │               │           │
             ▼               ▼           ▼
        ┌─────────┐    ┌─────────┐  ┌─────────┐
        │  app1   │    │  app2   │  │  app3   │
        │ Pod     │    │ Pod     │  │ Pod     │
        │ (nginx) │    │ (nginx) │  │ (nginx) │
        └─────────┘    └─────────┘  └─────────┘
```

### Learning Objectives

- Deploy applications on Kubernetes
- Use ConfigMaps to manage application content
- Create Services to expose applications internally
- Set up Ingress rules for external access
- Understand host-based routing
- Test multi-application deployments

---

## 🛠️ Prerequisites

- ✅ **Completed Part 1** (working K3s cluster)
- **kubectl**: For applying manifests (or use vagrant ssh)
- **curl**: For testing endpoints
- **Host file editing**: For DNS resolution (`/etc/hosts`)

---

## 🚀 Quick Start

```bash
cd p2
vagrant up                      # Start the VM and K3s
```

Wait for provisioning to complete (~3-5 minutes).

### Deploy Applications

Using kubectl from host:
```bash
export KUBECONFIG=$(pwd)/k3s.yaml
kubectl apply -f app1.yaml
kubectl apply -f app2.yaml
kubectl apply -f app3.yaml
kubectl apply -f ingress.yaml
```

Or using vagrant ssh:
```bash
vagrant ssh -c "kubectl apply -f /vagrant/app1.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/app2.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/app3.yaml"
vagrant ssh -c "kubectl apply -f /vagrant/ingress.yaml"
```

---

## ✅ Testing & Verification

### Test 1: Verify K3s is Running

```bash
export KUBECONFIG=$(pwd)/k3s.yaml

# Check node status
kubectl get nodes

# Expected:
# NAME       STATUS   ROLES                  AGE   VERSION
# HAMEUR-S   Ready    control-plane,master   2m    v1.30.x
```

✅ **Success**: Node shows Ready status

### Test 2: Verify Applications Deployed

```bash
# Check if ConfigMaps exist
kubectl get configmap
```

**Expected**:
```
NAME           DATA   AGE
app1-html      1      1m
app2-html      1      1m
app3-html      1      1m
```

✅ **Success**: All ConfigMaps created

### Test 3: Verify Pods Are Running

```bash
# Check pods
kubectl get pods

# Check pod details
kubectl describe pods
```

**Expected output**:
```
NAME                    READY   STATUS    RESTARTS   AGE
app1-5c7c9d4b4c-xxxxx    1/1     Running   0          1m
app2-5c7c9d4b4c-yyyyy    1/1     Running   0          1m
app3-5c7c9d4b4c-zzzzz    1/1     Running   0          1m
```

✅ **Success**: All pods are Running

### Test 4: Verify Services

```bash
# Check services
kubectl get svc

# Get service details
kubectl describe svc app1
kubectl describe svc app2
kubectl describe svc app3
```

**Expected**:
```
NAME              TYPE        CLUSTER-IP       PORT(S)   AGE
app1              ClusterIP   10.43.xxx.xxx    80/TCP    1m
app2              ClusterIP   10.43.xxx.xxx    80/TCP    1m
app3              ClusterIP   10.43.xxx.xxx    80/TCP    1m
```

✅ **Success**: Services created and assigned ClusterIPs

### Test 5: Verify Ingress Configuration

```bash
# Check ingress rules
kubectl get ingress

# Get ingress details
kubectl describe ingress main-ingress
```

**Expected**:
```
NAME            CLASS    HOSTS                  ADDRESS         PORTS   AGE
main-ingress    <none>   app1.com, app2.com     192.168.56.110  80      1m
```

✅ **Success**: Ingress created with correct rules

### Test 6: Setup DNS Resolution (Host Machine)

Update your `/etc/hosts` file:

```bash
# On Linux/Mac
echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
```

On Windows (as Administrator):
```
C:\Windows\System32\drivers\etc\hosts

Add:
192.168.56.110 app1.com
192.168.56.110 app2.com
```

### Test 7: Test Applications via Ingress

```bash
# Test app1 (via hostname)
curl http://app1.com
# Expected: "Hello from app1."

# Test app2 (via hostname)
curl http://app2.com
# Expected: "Hello from app2."

# Test app3 (default backend, via IP)
curl http://192.168.56.110
# Expected: "Hello from app3."
```

✅ **Success**: All applications accessible and returning correct content

### Test 8: Test Direct Pod Access (SSH into VM)

```bash
vagrant ssh

# Inside VM - get pod IPs
kubectl get pods -o wide

# Test pod directly
curl http://10.42.0.x:80    # Replace with actual pod IP

# Check Traefik logs
kubectl logs -n kube-system -l app=traefik
```

✅ **Success**: Can access pods directly from cluster

### Test 9: Ingress Routing Logic Verification

```bash
# Test with explicit headers
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110

# Both should route correctly to their respective apps
```

✅ **Success**: Host-based routing works correctly

### Test 10: Service Endpoint Verification

```bash
# Check service endpoints
kubectl get endpoints

# Expected:
# NAME            ENDPOINTS          AGE
# app1            10.42.0.x:80       2m
# app2            10.42.0.y:80       2m
# app3            10.42.0.z:80       2m
```

✅ **Success**: Services have active endpoints

---

## 📊 Full Integration Test Suite

Save this as `test_p2.sh`:

```bash
#!/bin/bash
set -e

export KUBECONFIG=$(pwd)/k3s.yaml

echo "========================================="
echo "Part 2: Application Deployment Tests"
echo "========================================="

# Wait for cluster to be ready
echo ""
echo "➤ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready node --all --timeout=300s

# Test 1: Check deployments
echo ""
echo "✓ Test 1: Checking deployments"
kubectl get deployments
if [ "$(kubectl get deployments -o jsonpath='{.items | length}')" -eq 3 ]; then
  echo "✓ All 3 deployments exist"
else
  echo "✗ Not all deployments found"
  exit 1
fi

# Test 2: Check pods
echo ""
echo "✓ Test 2: Checking pods are ready"
kubectl wait --for=condition=ready pod --all --timeout=60s
kubectl get pods

# Test 3: Check services
echo ""
echo "✓ Test 3: Checking services"
kubectl get services
if [ "$(kubectl get services --field-selector metadata.name!=kubernetes -o jsonpath='{.items | length}')" -eq 3 ]; then
  echo "✓ All 3 services exist"
else
  echo "✗ Not all services found"
  exit 1
fi

# Test 4: Check ingress
echo ""
echo "✓ Test 4: Checking ingress"
kubectl get ingress
if [ "$(kubectl get ingress -o jsonpath='{.items | length}')" -ge 1 ]; then
  echo "✓ Ingress rule exists"
else
  echo "✗ No ingress found"
  exit 1
fi

# Test 5: Test service endpoints
echo ""
echo "✓ Test 5: Verifying endpoints"
kubectl get endpoints
ENDPOINTS=$(kubectl get endpoints -o jsonpath='{.items[].subsets[].addresses | length}')
if [ "$ENDPOINTS" -gt 0 ]; then
  echo "✓ Endpoints are active"
else
  echo "✗ No active endpoints"
  exit 1
fi

# Test 6: Test Traefik
echo ""
echo "✓ Test 6: Verifying Traefik (Ingress Controller)"
TRAEFIK=$(kubectl get pods -n kube-system -l app=traefik -o jsonpath='{.items | length}')
if [ "$TRAEFIK" -ge 1 ]; then
  echo "✓ Traefik pod is running"
else
  echo "✗ Traefik not running"
  exit 1
fi

# Test 7: Port forward and test
echo ""
echo "✓ Test 7: Testing application access"

# Get first pod and port-forward
POD=$(kubectl get pods -o jsonpath='{.items[0].metadata.name}')
echo "Testing pod: $POD"

kubectl port-forward "pod/$POD" 8888:80 &
PF_PID=$!
sleep 2

if curl -s http://localhost:8888 | grep -q "app"; then
  echo "✓ Pod responds correctly"
else
  echo "✗ Pod not responding"
  kill $PF_PID
  exit 1
fi

kill $PF_PID

echo ""
echo "========================================="
echo "✅ All tests passed!"
echo "========================================="
```

Run it:
```bash
bash test_p2.sh
```

---

## 🔧 Useful Commands

### Pod Management

```bash
# Get pod details
kubectl get pods -o wide

# View pod logs
kubectl logs <pod-name>

# Port forward to pod
kubectl port-forward pod/<pod-name> 8080:80

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Service Management

```bash
# Get service details
kubectl describe svc <service-name>

# Get service endpoints
kubectl get endpoints <service-name>

# Check service DNS name
kubectl exec <pod-name> -- nslookup <service-name>
```

### Ingress Management

```bash
# View ingress rules
kubectl describe ingress main-ingress

# Check ingress events
kubectl get events --field-selector involvedObject.name=main-ingress

# Check Traefik logs
kubectl logs -n kube-system -l app=traefik -f
```

### Configuration Management

```bash
# View ConfigMap content
kubectl get configmap app1-html -o yaml

# Edit ConfigMap
kubectl edit configmap app1-html

# Describe ConfigMap usage
kubectl describe configmap app1-html
```

---

## 🐛 Troubleshooting

### Problem: Pods show "ImagePullBackOff"

```bash
# Check pod events
kubectl describe pod <pod-name>

# Solution: nginx:alpine should be available. If not:
kubectl delete pod <pod-name>  # Let deployment recreate it
```

### Problem: Service has no endpoints

```bash
# Check service selector
kubectl get service app1 -o yaml | grep -A 5 selector

# Check if pods match the selector
kubectl get pods --show-labels

# Solution: Ensure pod labels match service selector
```

### Problem: Ingress not routing traffic

```bash
# Check ingress configuration
kubectl describe ingress main-ingress

# Check Traefik logs
kubectl logs -n kube-system -l app=traefik

# Test from inside pod
kubectl exec <pod-name> -- curl http://app1
```

### Problem: Can't resolve hostnames

```bash
# On host machine: check /etc/hosts
cat /etc/hosts | grep app

# If not there, add it:
echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts

# Test DNS resolution
nslookup app1.com
```

### Problem: Port 80 bind failed

```bash
# Check if port is in use
sudo lsof -i :80

# Use different port in Vagrant/forwarded_port if needed
```

---

## 📚 Understanding Ingress

### How Ingress Works

```
1. Client browser sends: GET http://app1.com
2. DNS resolves: app1.com → 192.168.56.110
3. HTTP request arrives at VM port 80
4. Traefik (ingress controller) receives it
5. Traefik checks ingress rules:
   - Rule: "Host: app1.com" → service: app1:80
6. Traefik routes to app1 Service ClusterIP
7. Service proxies to pod (load balanced)
8. Pod (nginx) handles request
9. Response sent back through same path
```

### ConfigMap for Content

Instead of building custom images, we use **ConfigMaps** to inject HTML:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app1-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>App1</title></head>
    <body><h1>Hello from app1.</h1></body>
    </html>
```

Then mounted to nginx:
```yaml
volumeMounts:
- name: html-volume
  mountPath: /usr/share/nginx/html
volumes:
- name: html-volume
  configMap:
    name: app1-html
```

---

## 🎯 What You're Learning

| Concept | What's Happening |
|---------|-----------------|
| **ConfigMap** | Store configuration outside containers |
| **Deployment** | Declaratively manage pod replicas |
| **Service** | Stable endpoint for accessing pods |
| **Ingress** | Route external HTTP traffic |
| **Traefik** | Ingress controller (built into K3s) |
| **Host-based routing** | Route by hostname (virtual hosting) |

---

## 📋 Cleanup

```bash
# Remove applications
kubectl delete -f ingress.yaml
kubectl delete -f app1.yaml
kubectl delete -f app2.yaml
kubectl delete -f app3.yaml

# Destroy VMs
vagrant destroy -f

# Remove DNS entries from /etc/hosts
# (manual removal required)
```

---

## 🎓 Next Steps

1. **Understand ConfigMaps better**: Experiment with different HTML content
2. **Add more applications**: Create app4.yaml following the same pattern
3. **Add path-based routing**: Change ingress to use paths instead of hosts
4. **Part 3**: Then move to GitOps with ArgoCD

---

## 📖 Further Reading

- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

---

## ✨ Summary

**Part 2 teaches you**:
- How to deploy applications on Kubernetes
- Managing configuration with ConfigMaps
- Exposing services internally and externally
- Ingress routing with Traefik
- Host-based virtual hosting
- Testing multi-application deployments

**Time to complete**: 20-40 minutes

**Difficulty**: ⭐⭐⭐ (Intermediate)

---

**Ready to test? Start with Test 1 above!** ✅

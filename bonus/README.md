# Bonus: Advanced Monitoring with Prometheus & Grafana

## 📌 Overview

This bonus part demonstrates **advanced Kubernetes operations** including:
- **Helm charts** for templated application deployment
- **Prometheus** for metrics collection and monitoring
- **Grafana** for visualization and dashboards
- **Multi-node cluster** with enhanced resource allocation

This is a more advanced setup with production-like monitoring stack, ideal for understanding how to observe and troubleshoot Kubernetes clusters.

### Architecture

```
┌──────────────────────────────────────┐
│   Kubernetes Cluster (K3s)            │
│   (HAMEUR-BONUS)                      │
│   4GB RAM, 2 CPUs                     │
└────────┬────────────────────────────┬─┘
         │                            │
         ▼                            ▼
    ┌─────────────┐           ┌──────────────┐
    │ Prometheus  │           │  Grafana     │
    │  Scrapes    │           │  Visualizes  │
    │  Metrics    │           │  Dashboards  │
    └─────┬───────┘           └──────┬───────┘
          │                         │
          └────────────┬───────────┘
                       │
          ┌────────────▼──────────────┐
          │   Metrics Data Store      │
          │ (TSDB - Time Series DB)   │
          └──────────────────────────┘
          
    Ports:
    - Prometheus: 30090 (NodePort)
    - Grafana: 30300 (NodePort)
    - K3s API: 6443
```

### Learning Objectives

- Install and configure Prometheus for metrics
- Use Grafana for visualization
- Deploy via Helm charts (templating)
- Understand metrics and monitoring concepts
- Set up dashboards and alerts
- Learn production-grade observability

---

## 🛠️ Prerequisites

- **Completed Parts 1-3** (understanding of Kubernetes)
- **Helm** (optional, but recommended): `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash`
- **System Resources**:
  - 4+ GB available RAM (Bonus uses 4GB per VM)
  - 20 GB free disk space
  - Multi-core processor recommended

---

## 🚀 Quick Start

### Step 1: Start the Bonus VM

```bash
cd bonus
vagrant up                  # Starts HAMEUR-BONUS VM
```

The setup will:
1. Install K3s on the bonus VM
2. Install Helm
3. Deploy Prometheus
4. Deploy Grafana
5. Configure dashboards

**Estimated time**: 10-15 minutes

### Step 2: Verify Deployment

```bash
# From host machine
export KUBECONFIG=$(pwd)/output/k3s.yaml    # If available, or ssh

# Or SSH into VM
vagrant ssh

# Check system pods
kubectl get pods -A
```

---

## ✅ Testing & Verification

### Test 1: Verify K3s is Running

```bash
export KUBECONFIG=$(pwd)/k3s.yaml

# Check node status
kubectl get nodes

# Expected:
NAME            STATUS   ROLES                   AGE   VERSION
HAMEUR-BONUS    Ready    control-plane,master    3m    v1.30.x
```

✅ **Success**: Node shows Ready status

### Test 2: Verify Helm Installation

```bash
# Check Helm version
helm version

# Expected output:
version.BuildInfo{Version:"v3.x.x", GitCommit:"...", GitTreeState:"clean", GoVersion:"..."}
```

✅ **Success**: Helm is installed and working

### Test 3: Verify Prometheus Deployment

```bash
# Check Prometheus pods
kubectl get pods -A | grep prometheus

# Expected:
prometheus-kube-prometheus-prometheus-0     1/1     Running

# Check Prometheus service
kubectl get svc -A | grep prometheus

# Expected:
prometheus-kube-prometheus-prometheus          NodePort   10.43.xxx.xxx   9090:30090/TCP
```

✅ **Success**: Prometheus is running

### Test 4: Verify Grafana Deployment

```bash
# Check Grafana pods
kubectl get pods -A | grep grafana

# Expected:
prometheus-grafana-xxxxx                   1/1     Running

# Check Grafana service
kubectl get svc -A | grep grafana

# Expected:
prometheus-grafana                              NodePort   10.43.xxx.xxx   80:30300/TCP
```

✅ **Success**: Grafana is running

### Test 5: Access Prometheus UI

```bash
# From host machine
# Open browser: http://192.168.56.110:30090

# Or port-forward
kubectl port-forward -n prometheus svc/prometheus-kube-prometheus-prometheus 9090:9090

# Then: http://localhost:9090
```

Check:
- ✅ Graph tab shows available metrics
- ✅ Status → Targets shows scraped targets
- ✅ Status → Configuration shows prometheus config

✅ **Success**: Prometheus UI accessible and collecting metrics

### Test 6: Access Grafana Dashboard

```bash
# From host machine
# Open browser: http://192.168.56.110:30300

# Or port-forward
kubectl port-forward -n prometheus svc/prometheus-grafana 3000:80

# Then: http://localhost:3000
```

Login with:
- **Username**: admin
- **Password**: prom-operator (default)

Check:
- ✅ Can login successfully
- ✅ Pre-built dashboards available
- ✅ Kubernetes cluster data visible

✅ **Success**: Grafana accessible with dashboards

### Test 7: Query Metrics

In Prometheus UI, try these queries:

```
# CPU usage
node_cpu_seconds_total

# Memory usage
node_memory_MemAvailable_bytes

# Pod count
count(kube_pod_info)

# Container restarts
increase(kube_pod_container_status_restarts_total[5m])
```

✅ **Success**: Can query and see metrics

### Test 8: Verify Helm Chart Installation

```bash
# Check installed Helm releases
helm list -A

# Expected:
NAME                    NAMESPACE       REVISION        UPDATED
prometheus              prometheus      1               2024-xx-xx...
grafana                 prometheus      1               2024-xx-xx...
```

✅ **Success**: Helm charts deployed

### Test 9: Check Metrics Collection

```bash
# In Prometheus UI (http://192.168.56.110:30090)
# Go to Status → Targets

# Look for:
✓ kubernetes-apiservers       UP
✓ kubernetes-nodes            UP
✓ kubernetes-nodes-cadvisor   UP
✓ kubernetes-pods             UP
✓ kubernetes-services         UP
```

✅ **Success**: All targets scraping successfully

### Test 10: Verify Data Persistence

```bash
# Check if PVCs are created
kubectl get pvc -A

# Expected:
prometheus-prometheus-kube-prometheus-prometheus-db
prometheus-grafana
```

✅ **Success**: Data persistence configured

---

## 📊 Full Monitoring Test Suite

Save as `test_bonus.sh`:

```bash
#!/bin/bash
set -e

export KUBECONFIG=$(pwd)/k3s.yaml

echo "========================================="
echo "Bonus: Monitoring Stack Tests"
echo "========================================="

# Test 1: Cluster status
echo ""
echo "✓ Test 1: Cluster Ready"
kubectl wait --for=condition=Ready node --all --timeout=300s
kubectl get nodes

# Test 2: Helm
echo ""
echo "✓ Test 2: Helm Installation"
helm version
RELEASES=$(helm list -A -o json | jq '.[] | length')
echo "✓ Found $RELEASES Helm releases"

# Test 3: Prometheus pods
echo ""
echo "✓ Test 3: Prometheus Pods"
PROM_PODS=$(kubectl get pods -n prometheus -l app.kubernetes.io/name=prometheus -o jsonpath='{.items | length}')
if [ "$PROM_PODS" -ge 1 ]; then
  echo "✓ Prometheus pods running ($PROM_PODS)"
else
  echo "✗ Prometheus pods not found"
  exit 1
fi

# Test 4: Grafana pods
echo ""
echo "✓ Test 4: Grafana Pods"
GRAFANA_PODS=$(kubectl get pods -n prometheus -l app.kubernetes.io/name=grafana -o jsonpath='{.items | length}')
if [ "$GRAFANA_PODS" -ge 1 ]; then
  echo "✓ Grafana pods running ($GRAFANA_PODS)"
else
  echo "✗ Grafana pods not found"
  exit 1
fi

# Test 5: Services
echo ""
echo "✓ Test 5: Services"
kubectl get svc -n prometheus
SVC_COUNT=$(kubectl get svc -n prometheus -o jsonpath='{.items | length}')
echo "✓ $SVC_COUNT services in prometheus namespace"

# Test 6: Metrics available
echo ""
echo "✓ Test 6: Metrics Collection"
TARGETS=$(kubectl get -n prometheus pods --all-namespaces -o json 2>/dev/null | jq '.items | length')
echo "✓ Monitoring $TARGETS pods"

# Test 7: PVCs for persistence
echo ""
echo "✓ Test 7: Data Persistence"
PVC_COUNT=$(kubectl get pvc -A -o jsonpath='{.items | length}')
if [ "$PVC_COUNT" -gt 0 ]; then
  echo "✓ $PVC_COUNT PVCs configured for persistence"
else
  echo "! No PVCs found (ephemeral storage)"
fi

# Test 8: Resource usage
echo ""
echo "✓ Test 8: Resource Usage"
kubectl top nodes || echo "! Metrics server may not be ready yet"
kubectl top pods -n prometheus --sort-by=memory || echo "! Metrics not yet available"

echo ""
echo "========================================="
echo "✅ Monitoring stack tests completed!"
echo "========================================="
```

Run it:
```bash
bash test_bonus.sh
```

---

## 🔧 Useful Commands

### Helm Commands

```bash
# List installed releases
helm list -A

# Show release details
helm show values prometheus-community/kube-prometheus-stack

# Upgrade release
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n prometheus

# Rollback release
helm rollback prometheus -n prometheus

# Delete release
helm uninstall prometheus -n prometheus
```

### Prometheus Commands

```bash
# Check targets status
kubectl get --all-namespaces endpoints prometheus

# Query metrics
# Go to http://192.168.56.110:30090 and use the UI

# Some useful queries:
# CPU: sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
# Memory: sum(container_memory_usage_bytes) by (pod)
# Network: sum(rate(container_network_receive_bytes_total[5m])) by (pod)
```

### Grafana Commands

```bash
# Get Grafana admin password (if using default)
kubectl get secret -n prometheus prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port-forward to Grafana
kubectl port-forward -n prometheus svc/prometheus-grafana 3000:80

# Access: http://localhost:3000
```

### Debugging

```bash
# Check pod logs
kubectl logs -n prometheus -l app.kubernetes.io/name=prometheus

# Describe Prometheus pod
kubectl describe pod -n prometheus -l app.kubernetes.io/name=prometheus

# Check ServiceMonitor (custom CRD for scraping)
kubectl get servicemonitor -A

# Check PrometheusRule (custom CRD for alerts)
kubectl get prometheusrule -A
```

---

## 🐛 Troubleshooting

### Problem: Prometheus not scraping targets

```bash
# Check Prometheus UI Status → Targets
# Should show UP status for all targets

# If DOWN:
kubectl logs -n prometheus -l app.kubernetes.io/name=prometheus | grep error

# Check ServiceMonitor configuration
kubectl get servicemonitor -A -o yaml
```

### Problem: Grafana not showing metrics

```bash
# Check data source configuration
# In Grafana UI: Configuration → Data Sources
# Should have Prometheus datasource pointing to http://prometheus-kube-prometheus-prometheus:9090

# Verify Prometheus is reachable from Grafana pod
kubectl exec -it -n prometheus <grafana-pod> -- \
  curl http://prometheus-kube-prometheus-prometheus:9090
```

### Problem: Out of memory

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n prometheus

# Reduce scrape frequency
helm upgrade prometheus prometheus-community/kube-prometheus-stack \
  -n prometheus \
  --set prometheus.prometheusSpec.retention=12h
```

### Problem: Persistent volumes not mounting

```bash
# Check PVC status
kubectl get pvc -n prometheus

# Check PV status
kubectl get pv

# Check storage class
kubectl get storageclass

# If local-path is not available:
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
```

---

## 📚 Understanding Monitoring Stack

### Prometheus

**Purpose**: Scrape and store metrics

**Key Components**:
- **Scraper**: Pulls metrics from targets
- **Storage**: Time-series database (TSDB)
- **Query Engine**: PromQL language
- **UI**: Graph and API interface

**Metrics Collected**:
- Node metrics (CPU, memory, disk)
- Pod metrics (CPU, memory, network)
- Container metrics
- Kubernetes API metrics
- Custom app metrics

### Grafana

**Purpose**: Visualize metrics and create dashboards

**Features**:
- Dashboards (pre-built and custom)
- Data sources (Prometheus, other systems)
- Alerting (send alerts on thresholds)
- Annotations (mark events on graphs)
- User management

### Helm Charts

**Purpose**: Template and package Kubernetes applications

**Benefits**:
- Reusable templates
- Version management
- Dependency handling
- Easy upgrades/rollbacks
- Values separation from templates

---

## 🎯 Common Dashboards to Explore

1. **Kubernetes Cluster**: Overall cluster health
2. **Kubernetes Nodes**: Node-specific metrics
3. **Kubernetes Pods**: Pod-level metrics
4. **Kubernetes Deployment**: Deployment status
5. **Prometheus**: Prometheus itself metrics

All pre-configured in the kube-prometheus-stack Helm chart.

---

## 📊 Creating Custom Dashboards

1. Go to Grafana UI (http://192.168.56.110:30300)
2. Click "+" → Dashboard
3. Add panels with metrics:
   ```
   - Panel title: CPU Usage
   - Data source: Prometheus
   - Metrics: node_cpu_seconds_total
   ```
4. Configure visualization (graph, gauge, etc.)
5. Save dashboard

---

## 🎓 Next Steps

### Integrate with CI/CD

Setup alerts to trigger on:
- High CPU usage
- Pod crashes
- Failed deployments
- Service down

### Multi-Cluster Monitoring

Use Prometheus federation to:
- Monitor multiple clusters
- Centralized dashboards
- Unified alerting

### Production Hardening

- Set up persistent storage
- Configure authentication
- Enable RBAC
- Add backup/restore
- Set up log aggregation (ELK/Loki)

---

## 📖 Further Reading

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Kubernetes Monitoring](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/)

---

## 📈 Key Metrics to Monitor

| Metric | Purpose | Alert Threshold |
|--------|---------|-----------------|
| CPU Usage | Node/pod performance | > 80% |
| Memory Usage | Resource exhaustion | > 85% |
| Disk Usage | Storage issues | > 90% |
| Pod Restarts | App stability | > 5 in 1h |
| Failed Pods | App health | > 0 |
| API Latency | API performance | > 1s |

---

## ✨ Summary

**Bonus teaches you**:
- Prometheus for metrics collection
- Grafana for visualization
- Helm for templated deployments
- Production-grade monitoring setup
- Dashboard creation and customization
- Observability best practices

**Time to complete**: 30-50 minutes

**Difficulty**: ⭐⭐⭐⭐⭐ (Expert)

**Recommended**: Complete Parts 1-3 before attempting Bonus

---

## 📋 Cleanup

```bash
# Remove Helm releases
helm uninstall prometheus -n prometheus
helm uninstall grafana -n prometheus

# Delete namespace
kubectl delete namespace prometheus

# Destroy VM
vagrant destroy -f
```

---

**Congratulations on completing IoT!** 🎉

You've learned:
- ✅ Kubernetes basics with K3s
- ✅ Application deployment
- ✅ Ingress routing
- ✅ GitOps with ArgoCD
- ✅ Advanced monitoring

**Next level**: Explore service mesh (Istio), serverless (Knative), or container registries!

---

**Ready to monitor? Start with Test 1 above!** ✅

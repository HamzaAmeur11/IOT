#!/bin/bash
set -e

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
source /vagrant/ips.conf

echo "========================================="
echo "Deploying Monitoring Stack with Helm"
echo "========================================="

kubectl create namespace monitoring 2>/dev/null || echo "Namespace monitoring already exists"

# ── Prometheus + Alertmanager ──────────────────────────────────────────────
echo "========================================="
echo "Installing kube-prometheus-stack"
echo "========================================="

helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f /vagrant/helm-values/prometheus-values.yaml \
  --timeout 10m \
  --wait

echo "Waiting for Prometheus pod..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=prometheus \
  -n monitoring \
  --timeout=300s 2>/dev/null || true

# ── Grafana ────────────────────────────────────────────────────────────────
echo "========================================="
echo "Installing Grafana"
echo "========================================="

helm upgrade --install grafana grafana/grafana \
  -n monitoring \
  -f /vagrant/helm-values/grafana-values.yaml \
  --timeout 10m \
  --wait

echo "Waiting for Grafana pod..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n monitoring \
  --timeout=300s 2>/dev/null || true

# ── Expose services as NodePorts ──────────────────────────────────────────
# kube-prometheus-stack names its services with the release name prefix.
# Release name = "prometheus", so services are:
#   prometheus-kube-prometheus-prometheus   (Prometheus)
#   prometheus-kube-prometheus-alertmanager (Alertmanager)

echo "========================================="
echo "Exposing Prometheus on NodePort 30090"
echo "========================================="

kubectl patch svc prometheus-kube-prometheus-prometheus \
  -n monitoring --type='json' \
  -p='[{"op":"replace","path":"/spec/type","value":"NodePort"},
       {"op":"add","path":"/spec/ports/0/nodePort","value":30090}]'

echo "========================================="
echo "Exposing Alertmanager on NodePort 30093"
echo "========================================="

kubectl patch svc prometheus-kube-prometheus-alertmanager \
  -n monitoring --type='json' \
  -p='[{"op":"replace","path":"/spec/type","value":"NodePort"},
       {"op":"add","path":"/spec/ports/0/nodePort","value":30093}]'

# ── Verify ─────────────────────────────────────────────────────────────────
echo ""
echo "Services after patching:"
kubectl get svc -n monitoring | grep -E "grafana|prometheus|alertmanager"

echo ""
echo "========================================="
echo "  Monitoring Stack Ready!"
echo "========================================="
echo ""
echo "  Grafana:      http://localhost:30300"
echo "                http://$SERVER_IP:30300"
echo "                Username: admin"
echo "                Password: admin123"
echo ""
echo "  Prometheus:   http://localhost:30090"
echo "                http://$SERVER_IP:30090"
echo ""
echo "  Alertmanager: http://localhost:30093"
echo "                http://$SERVER_IP:30093"
echo ""
echo "========================================="

kubectl get pods -n monitoring

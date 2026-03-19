#!/bin/bash

# Load IPs from ips.conf
source /vagrant/ips.conf

echo "========================================="
echo "Deploying Monitoring Stack with Helm"
echo "========================================="

# Create monitoring namespace
kubectl create namespace monitoring

echo "========================================="
echo "Installing Prometheus Stack"
echo "========================================="

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f /vagrant/helm-values/prometheus-values.yaml \
  --wait

# Wait for Prometheus to be ready
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=300s 2>/dev/null || true

echo "========================================="
echo "Installing Grafana"
echo "========================================="

helm install grafana grafana/grafana \
  -n monitorinhelm-values/grafana-values.yaml \
  --wait
  -f /vagrant/grafana-values.yaml

# Wait for Grafana to be ready
echo "Waiting for Grafana to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=300s 2>/dev/null || true

echo "========================================="
echo "Exposing Prometheus and Alertmanager"
echo "========================================="

# Patch Prometheus service to NodePort
kubectl patch svc prometheus-operated -n monitoring --type='json' \
  -p='[{"op": "replace", "path": "/spec/type", "value":"NodePort"}]' 2>/dev/null || true

# Get NodePort for Prometheus
PROM_PORT=$(kubectl get svc prometheus-operated -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30090")

echo "========================================="
echo "Monitoring Stack Deployed!"
echo "========================================="
echo ""
echo "Access URLs:"
echo "  Grafana:     http://$SERVER_IP:30300"
echo "               Username: admin"
echo "               Password: admin123"
echo ""
echo "  Prometheus:  http://$SERVER_IP:$PROM_PORT"
echo ""
echo "========================================="

# Save info to shared folder
cat > /vagrant/monitoring-info.txt <<EOF
Grafana:     http://$SERVER_IP:30300
             Username: admin
             Password: admin123

Prometheus:  http://$SERVER_IP:$PROM_PORT

AlertManager: http://$SERVER_IP:30093
EOF

chmod 644 /vagrant/monitoring-info.txt

echo "Monitoring stack deployed successfully!"

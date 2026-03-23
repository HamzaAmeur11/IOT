#!/bin/bash
set -e

export KUBECONFIG=/root/.kube/config

echo "=== Creating dev namespace ==="
kubectl create namespace dev 2>/dev/null || echo "Namespace dev already exists"

echo "=== Applying ArgoCD Application manifest ==="
# This is the ONLY manifest we apply manually.
# ArgoCD will read deployment.yaml / service.yaml / ingress.yaml
# from GitHub and deploy them automatically.
kubectl apply -f /vagrant/confs/argocd-app.yaml

echo "=== Waiting for ArgoCD to sync the application ==="
for i in $(seq 1 36); do
    STATUS=$(kubectl get application playground-app -n argocd \
        -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Pending")
    HEALTH=$(kubectl get application playground-app -n argocd \
        -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    echo "[$i/36] Sync: $STATUS | Health: $HEALTH"
    if [ "$STATUS" = "Synced" ] && [ "$HEALTH" = "Healthy" ]; then
        echo "Application synced and healthy!"
        break
    fi
    sleep 10
done

echo ""
echo "=== Deployment complete ==="
echo ""
echo "Namespaces:"
kubectl get ns | grep -E "argocd|dev"
echo ""
echo "Pods in dev:"
kubectl get pods -n dev
echo ""
echo "App endpoint: http://localhost:8888"
echo "ArgoCD UI:    https://localhost:8080  (run port-forward first)"

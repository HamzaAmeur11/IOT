#!/bin/bash
set -e

export KUBECONFIG=/root/.kube/config

echo "=== Installing ArgoCD ==="

if kubectl get namespace argocd &>/dev/null; then
    echo "ArgoCD namespace already exists, skipping installation"
else
    kubectl create namespace argocd

    # Use --server-side to avoid "annotation too long" error on large CRDs
    # (notably applicationsets.argoproj.io exceeds the 262144-byte client-side limit)
    kubectl apply -n argocd \
        --server-side \
        --force-conflicts \
        -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    echo "=== Waiting for ArgoCD CRDs to be established ==="
    kubectl wait --for=condition=established \
        crd/applications.argoproj.io \
        crd/applicationsets.argoproj.io \
        crd/appprojects.argoproj.io \
        --timeout=120s

    echo "=== Waiting for ArgoCD server to be ready ==="
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=argocd-server \
        -n argocd \
        --timeout=300s

    echo "=== Waiting for ArgoCD application controller to be ready ==="
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=argocd-application-controller \
        -n argocd \
        --timeout=300s
fi

echo "=== ArgoCD installed successfully ==="

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "============================================"
echo "  ArgoCD is ready!"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo "  UI: https://localhost:8080 (after port-forward)"
echo "============================================"
echo ""

#!/bin/bash
set -e

export KUBECONFIG=/root/.kube/config

echo "=== Setting up ArgoCD port-forward as a systemd service ==="

# Write a small wrapper script that kubectl port-forward will run from
cat > /usr/local/bin/argocd-portforward.sh << 'SCRIPT'
#!/bin/bash
export KUBECONFIG=/root/.kube/config
while true; do
    echo "[$(date)] Starting ArgoCD port-forward on 0.0.0.0:8080 -> argocd-server:443"
    kubectl port-forward svc/argocd-server \
        -n argocd \
        --address 0.0.0.0 \
        8080:443 2>&1
    echo "[$(date)] Port-forward exited, restarting in 5s..."
    sleep 5
done
SCRIPT
chmod +x /usr/local/bin/argocd-portforward.sh

# Install as a systemd service so it starts on boot and auto-restarts
cat > /etc/systemd/system/argocd-portforward.service << 'SERVICE'
[Unit]
Description=ArgoCD kubectl port-forward
After=network.target k3d-iot-cluster.service
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/argocd-portforward.sh
Restart=always
RestartSec=5
Environment=KUBECONFIG=/root/.kube/config

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable argocd-portforward
systemctl start argocd-portforward

# Give it a moment to start
sleep 5

# Verify it is running
if systemctl is-active --quiet argocd-portforward; then
    echo "Port-forward service is running"
else
    echo "Warning: port-forward service failed to start, check: journalctl -u argocd-portforward"
fi

# ── Print the ArgoCD admin password ───────────────────────────────────────
echo ""
echo "============================================"
echo "  ArgoCD is ready!"
echo ""
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 -d)
echo "  Username : admin"
echo "  Password : $PASSWORD"
echo ""
echo "  Open in your browser (on your HOST machine):"
echo "  https://localhost:8080"
echo ""
echo "  App endpoint:"
echo "  http://localhost:8888"
echo "============================================"
echo ""

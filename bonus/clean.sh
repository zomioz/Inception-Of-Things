#!/bin/bash

set -e

echo "========================================="
echo "   Cleaning everything...                "
echo "========================================="

# ─── KILL PORT FORWARDS ──────────────────────
echo "[1/7] Killing port forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true
echo "✅ Port forwards killed!"

# ─── DELETE K3D CLUSTER ──────────────────────
echo "[2/7] Deleting K3d clusters..."
sudo k3d cluster delete --all 2>/dev/null || true
echo "✅ K3d clusters deleted!"

# ─── REMOVE KUBECONFIG ───────────────────────
echo "[3/7] Removing kubeconfig..."
rm -rf ~/.kube 2>/dev/null || true
echo "✅ Kubeconfig removed!"

# ─── REMOVE TMP FILES ────────────────────────
echo "[4/7] Removing tmp files..."
rm -rf /tmp/iot-confs 2>/dev/null || true
echo "✅ Tmp files removed!"

# ─── UNINSTALL BINARIES ──────────────────────
echo "[5/7] Removing binaries..."
sudo rm -f /usr/local/bin/kubectl   2>/dev/null || true
sudo rm -f /usr/local/bin/k3d       2>/dev/null || true
sudo rm -f /usr/local/bin/helm      2>/dev/null || true
sudo rm -f /usr/local/bin/argocd    2>/dev/null || true
echo "✅ Binaries removed!"

# ─── REMOVE DOCKER ───────────────────────────
echo "[6/7] Removing Docker..."
sudo systemctl stop docker 2>/dev/null || true
sudo apt-get remove -y docker.io 2>/dev/null || true
sudo apt-get purge -y docker.io 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true
sudo rm -rf /var/lib/docker 2>/dev/null || true
sudo rm -rf /etc/docker 2>/dev/null || true
echo "✅ Docker removed!"

# ─── REMOVE HELM REPOS ───────────────────────
echo "[7/7] Removing Helm repos cache..."
rm -rf ~/.cache/helm 2>/dev/null || true
rm -rf ~/.config/helm 2>/dev/null || true
rm -rf ~/.local/share/helm 2>/dev/null || true
echo "✅ Helm cache removed!"

echo ""
echo "========================================="
echo "   ✅ Everything cleaned!                "
echo "========================================="

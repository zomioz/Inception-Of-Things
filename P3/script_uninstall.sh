#!/bin/bash

echo "========================================="
echo "   Starting cleanup process...           "
echo "========================================="

# ─── 1. SUPPRIMER LE CLUSTER K3D ─────────────
echo "[1/5] Deleting k3d cluster..."
sudo k3d cluster delete mycluster 2>/dev/null || echo "No cluster to delete"

# ─── 2. DÉSINSTALLER K3D ─────────────────────
echo "[2/5] Uninstalling k3d..."
sudo rm -f /usr/local/bin/k3d

# ─── 3. DÉSINSTALLER KUBECTL ─────────────────
echo "[3/5] Uninstalling kubectl..."
sudo rm -f /usr/local/bin/kubectl

# ─── 4. DÉSINSTALLER ARGO CD CLI ─────────────
echo "[4/5] Uninstalling ArgoCD CLI..."
sudo rm -f /usr/local/bin/argocd

# ─── 5. DÉSINSTALLER DOCKER ──────────────────
echo "[5/5] Uninstalling Docker..."
sudo systemctl stop docker 2>/dev/null || true
sudo apt-get purge -y docker.io
sudo apt-get autoremove -y
sudo rm -rf /var/lib/docker
sudo rm -rf /etc/docker
sudo rm -f /etc/apt/sources.list.d/docker.list

# ─── NETTOYAGE KUBECONFIG ─────────────────────
echo "Cleaning kubeconfig..."
rm -rf ~/.kube

echo ""
echo "========================================="
echo "   Cleanup complete! Clean state ✅      "
echo "========================================="

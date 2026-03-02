#!/bin/bash

set -e  # Stop si une commande échoue

echo "========================================="
echo "   Starting installation process...      "
echo "========================================="

# ─── 1. DOCKER ───────────────────────────────
echo "[1/6] Installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker.io curl

echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# ─── 2. K3D ──────────────────────────────────
echo "[2/6] Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# ─── 3. KUBECTL ──────────────────────────────
echo "[3/6] Installing kubectl..."
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
echo "kubectl version: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# ─── 4. CLUSTER K3D ──────────────────────────
echo "[4/6] Creating k3d cluster 'mycluster'..."
sudo docker ps > /dev/null 2>&1  # test docker fonctionne avec sudo
sudo k3d cluster create mycluster --wait

# Récupérer le kubeconfig
mkdir -p ~/.kube
sudo k3d kubeconfig get mycluster > ~/.kube/config
chmod 600 ~/.kube/config

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# ─── 5. NAMESPACES ───────────────────────────
echo "[5/6] Creating namespaces..."
kubectl create namespace argocd
kubectl create namespace dev

# ─── 6. ARGO CD ──────────────────────────────
echo "[6/6] Installing Argo CD..."
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=120s

# ─── ARGO CD CLI ─────────────────────────────
echo "Installing Argo CD CLI..."
ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest \
  | grep tag_name | cut -d '"' -f4)
curl -sSL -o argocd \
  "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/argocd

# ─── DÉPLOYER L'APP VIA ARGO CD ──────────────  ← NOUVEAU
echo "Deploying application via Argo CD..."
kubectl apply -f confs/argocd-app.yaml           # ← NOUVEAU

# ─── RÉCUPÉRER MOT DE PASSE ARGO CD ──────────
echo ""
echo "========================================="
echo "   Installation complete!                "
echo "========================================="
echo ""
echo "Argo CD admin password:"
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode
echo ""
echo ""
echo "To access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"
echo ""
echo "NOTE: Log out and back in (or run 'newgrp docker') for docker group to take effect."

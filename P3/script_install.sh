#!/bin/bash

echo "Starting installation process..."

echo "Installing k3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "Updating package list..."
sudo apt-get update -y
echo "Installing docker.io..."
sudo apt install -y docker.io

echo "Starting and enabling docker service..."
sudo systemctl start docker
sudo systemctl enable docker
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

echo "Installing kubectl..."
curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
echo "Creating k3d cluster 'mycluster'..."
k3d cluster create mycluster

echo "Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Installing ArgoCD CLI..."
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd-linux-amd64
sudo mv argocd-linux-amd64 /usr/local/bin/argocd

echo "Installation complete!"
echo "Note: You may need to log out and back in for docker group changes to take effect."
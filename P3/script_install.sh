#!/bin/bash

echo -e '\033[0;32m' "Starting installation process..." '\033[1;37m' 

echo -e '\033[0;32m' "Installing k3d..." '\033[1;37m'
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo -e '\033[0;32m' "Updating package list..." '\033[1;37m'
sudo apt-get update -y
echo -e '\033[0;32m' "Installing docker.io..." '\033[1;37m'
sudo apt install -y docker.io

echo -e '\033[0;32m' "Starting and enabling docker service..." '\033[1;37m'
sudo systemctl start docker
sudo systemctl enable docker
echo -e '\033[0;32m' "Adding user to docker group..." '\033[1;37m'
sudo usermod -aG docker $USER

echo -e '\033[0;32m' "Installing kubectl..." '\033[1;37m'
curl -LO https://dl.k8s.io/release/v1.35.0/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
echo -e '\033[0;32m' "Creating k3d cluster 'mycluster'..." '\033[1;37m'
sg docker -c "k3d cluster create mycluster"

echo -e '\033[0;32m' "Installing ArgoCD..." '\033[1;37m'
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e '\033[0;32m' "Waiting for ArgoCD to be ready..." '\033[1;37m'
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo -e '\033[0;32m' "Deploying ArgoCD Application..." '\033[1;37m'
kubectl apply -f ./P3/argocd/argocd-basic.yaml

echo -e '\033[0;32m' "Retrieving ArgoCD admin password..." '\033[1;37m'
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > ./P3/argocd/Password
echo "" >> ./P3/argocd/Password

echo -e '\033[0;32m' "Installation complete!" '\033[1;37m'
echo "Note: You may need to log out and back in for docker group changes to take effect."

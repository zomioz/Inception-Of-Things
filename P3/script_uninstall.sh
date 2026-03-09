#!/bin/bash

echo "Starting uninstallation process..."

# Delete dev namespace (where ArgoCD deploys applications)
echo "Removing dev namespace and deployed applications..."
kubectl delete namespace dev --ignore-not-found=true || true

# Delete ArgoCD resources and namespace
echo "Removing ArgoCD from Kubernetes..."
kubectl delete namespace argocd --ignore-not-found=true || true

# Delete k3d cluster
echo "Deleting k3d cluster 'mycluster'..."
sg docker -c "k3d cluster delete mycluster" || sudo k3d cluster delete mycluster || true

# Remove kubectl
echo "Removing kubectl..."
sudo rm /usr/local/bin/kubectl || true

# Remove user from docker group
echo "Removing user from docker group..."
sudo gpasswd -d $USER docker || true

# Stop and disable docker
echo "Stopping and disabling docker..."
sudo systemctl stop docker || true
sudo systemctl disable docker || true

# Uninstall docker.io
echo "Uninstalling docker.io..."
sudo apt-get remove -y docker.io
sudo apt-get purge -y docker.io
sudo apt-get autoremove -y

# Uninstall k3d
echo "Removing k3d..."
sudo rm /usr/bin/k3d || true

#Delete password file
rm -f ./P3/argocd/Password

#Remove the hosts from /etc/hosts
sudo sed -i '/argocd\.local/d' /etc/hosts
sudo sed -i '/wil42\.local/d' /etc/hosts

echo "Uninstallation complete!"
echo "Note: You may need to log out and back in for group changes to take effect."

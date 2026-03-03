#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Uninstallation Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Confirm uninstallation
read -p "Are you sure you want to uninstall GitLab? This will delete all data. (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Uninstallation cancelled.${NC}"
    exit 0
fi

# Check if Helm is available
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Helm not found. Skipping Helm uninstall.${NC}"
else
    # Uninstall GitLab Helm release
    echo -e "${GREEN}Uninstalling GitLab Helm release...${NC}"
    helm uninstall gitlab -n gitlab 2>/dev/null || echo -e "${YELLOW}GitLab release not found or already uninstalled.${NC}"
fi

# Delete gitlab namespace
echo -e "${GREEN}Deleting namespace 'gitlab'...${NC}"
kubectl delete namespace gitlab --ignore-not-found=true --timeout=120s

# Wait for namespace deletion
echo -e "${GREEN}Waiting for namespace deletion...${NC}"
kubectl wait --for=delete namespace/gitlab --timeout=180s 2>/dev/null || echo -e "${YELLOW}Namespace already deleted.${NC}"

# Remove GitLab Helm repository
if command -v helm &> /dev/null; then
    echo -e "${GREEN}Removing GitLab Helm repository...${NC}"
    helm repo remove gitlab 2>/dev/null || echo -e "${YELLOW}GitLab repo not found.${NC}"
fi

# Delete password file
echo -e "${GREEN}Removing password file...${NC}"
rm -f ./bonus/GITLAB_ROOT_PASSWORD

# Remove PVCs if they still exist (force cleanup)
echo -e "${GREEN}Cleaning up persistent volume claims...${NC}"
kubectl delete pvc --all -n gitlab 2>/dev/null || true

# Remove gitlab.local from /etc/hosts
echo -e "${GREEN}Removing gitlab.local from /etc/hosts...${NC}"
sudo sed -i '/gitlab.local/d' /etc/hosts 2>/dev/null || echo -e "${YELLOW}Could not modify /etc/hosts${NC}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Uninstallation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read -p "This will delete GitLab, ArgoCD and all bonus data. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then exit 0; fi

# ── 1. Uninstall GitLab ───────────────────────────────────────────────────────

echo -e "${GREEN}Uninstalling GitLab Helm release...${NC}"
helm uninstall gitlab -n gitlab 2>/dev/null || true

echo -e "${GREEN}Deleting namespace gitlab...${NC}"
kubectl delete namespace gitlab --ignore-not-found

echo -e "${GREEN}Removing GitLab Helm repository...${NC}"
helm repo remove gitlab 2>/dev/null || true

# ── 2. Delete ArgoCD (bonus config) ──────────────────────────────────────────

echo -e "${GREEN}Deleting namespace argocd...${NC}"
kubectl delete namespace argocd --ignore-not-found

# ── 3. Delete dev namespace (created by ArgoCD sync) ─────────────────────────

echo -e "${GREEN}Deleting namespace dev...${NC}"
kubectl delete namespace dev --ignore-not-found

# ── 4. Remove generated files ─────────────────────────────────────────────────

echo -e "${GREEN}Removing generated token files...${NC}"
rm -f "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD"
rm -f "${SCRIPT_DIR}/GITLAB_API_TOKEN"

# ── 5. Remove /etc/hosts entries ─────────────────────────────────────────────

echo -e "${GREEN}Removing entries from /etc/hosts...${NC}"
sudo sed -i '/gitlab\.local/d' /etc/hosts
sudo sed -i '/argocd\.local/d' /etc/hosts
sudo sed -i '/wil42\.local/d' /etc/hosts

echo -e "${GREEN}Done! To restore P3, run: bash ../P3/script_install.sh${NC}"

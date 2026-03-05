#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Install Helm ───────────────────────────────────────────────────────────

echo -e "${GREEN}Installing Helm...${NC}"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ── 2. Create GitLab namespace ────────────────────────────────────────────────

echo -e "${GREEN}Creating gitlab namespace...${NC}"
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# ── 3. Add GitLab Helm repo ───────────────────────────────────────────────────

echo -e "${GREEN}Adding GitLab Helm repository...${NC}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# ── 4. Install GitLab ─────────────────────────────────────────────────────────

echo -e "${GREEN}Installing GitLab via Helm (this takes ~15-20 min)...${NC}"
helm install gitlab gitlab/gitlab \
    --namespace gitlab \
    --values "${SCRIPT_DIR}/gitlab/gitlab-values.yaml" \
    --timeout 20m \
    --wait

# ── 5. Wait for GitLab webservice ─────────────────────────────────────────────

echo -e "${GREEN}Waiting for GitLab webservice to be ready...${NC}"
kubectl rollout status deployment/gitlab-webservice-default -n gitlab --timeout=600s

# ── 5b. Apply GitLab ingress ──────────────────────────────────────────────────

echo -e "${GREEN}Applying GitLab ingress...${NC}"
kubectl apply -f "${SCRIPT_DIR}/gitlab/gitlab-ingress.yaml"

# ── 6. Save root password ─────────────────────────────────────────────────────

echo -e "${GREEN}Saving GitLab root password...${NC}"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
    -o jsonpath="{.data.password}" | base64 -d > "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD"
echo ""
echo -e "${GREEN}Password saved to bonus/GITLAB_ROOT_PASSWORD${NC}"

# ── 7. Add entries to /etc/hosts ──────────────────────────────────────────────

echo -e "${GREEN}Adding hosts to /etc/hosts...${NC}"
grep -q "gitlab.local"  /etc/hosts || echo "127.0.0.1 gitlab.local"  | sudo tee -a /etc/hosts
grep -q "argocd.local"  /etc/hosts || echo "127.0.0.1 argocd.local"  | sudo tee -a /etc/hosts
grep -q "wil42.local"   /etc/hosts || echo "127.0.0.1 wil42.local"   | sudo tee -a /etc/hosts

# ── 8. Run ArgoCD integration ─────────────────────────────────────────────────

echo -e "${GREEN}Running ArgoCD integration...${NC}"
bash "${SCRIPT_DIR}/script_argocd_integration.sh"

echo -e "${GREEN}Done! GitLab is available at http://gitlab.local${NC}"
echo -e "${GREEN}Root password: $(cat "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD")${NC}"

#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Minimal Installation Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if kubectl is available
echo -e "${GREEN}Checking kubectl...${NC}"
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if cluster is running
echo -e "${GREEN}Checking Kubernetes cluster...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Kubernetes cluster is not running. Please start your cluster first.${NC}"
    exit 1
fi

# Check available memory
echo -e "${GREEN}Checking available resources...${NC}"
AVAILABLE_MEMORY=$(kubectl top node 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
if [ ! -z "$AVAILABLE_MEMORY" ] && [ "$AVAILABLE_MEMORY" -gt 85 ]; then
    echo -e "${YELLOW}Warning: Memory usage is high (${AVAILABLE_MEMORY}%).${NC}"
    echo -e "${YELLOW}GitLab requires ~2-3Gi RAM. Consider freeing some resources.${NC}"
    read -p "Continue anyway? (yes/no): " CONTINUE
    if [ "$CONTINUE" != "yes" ]; then
        exit 0
    fi
fi

# Check if Traefik is running
echo -e "${GREEN}Checking Traefik ingress controller...${NC}"
if ! kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik | grep -q Running; then
    echo -e "${RED}Traefik ingress controller is not running.${NC}"
    echo -e "${RED}GitLab requires an ingress controller. Please install one first.${NC}"
    exit 1
fi

# Check if Helm is installed
echo -e "${GREEN}Checking Helm installation...${NC}"
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}Helm not found. Installing Helm...${NC}"
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Helm.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Helm installed successfully!${NC}"
else
    echo -e "${GREEN}Helm is already installed: $(helm version --short)${NC}"
fi

# Create gitlab namespace
echo -e "${GREEN}Creating namespace 'gitlab'...${NC}"
kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -

# Add GitLab Helm repository
echo -e "${GREEN}Adding GitLab Helm repository...${NC}"
helm repo add gitlab https://charts.gitlab.io/
helm repo update

# Install GitLab with minimal configuration
echo -e "${GREEN}Installing GitLab (this may take several minutes)...${NC}"
echo -e "${YELLOW}Note: GitLab installation is resource-intensive. Please be patient.${NC}"

helm install gitlab gitlab/gitlab \
  --namespace gitlab \
  --values ./bonus/gitlab-values.yaml \
  --timeout 10m \
  --wait

if [ $? -ne 0 ]; then
    echo -e "${RED}GitLab installation failed. Please check the error messages above.${NC}"
    exit 1
fi

# Wait for GitLab to be fully ready
echo -e "${GREEN}Waiting for GitLab pods to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=600s

# Get GitLab root password
echo -e "${GREEN}Retrieving GitLab root password...${NC}"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath="{.data.password}" | base64 -d > ./bonus/GITLAB_ROOT_PASSWORD
echo "" >> ./bonus/GITLAB_ROOT_PASSWORD

# Add gitlab.local to /etc/hosts if not present
echo -e "${GREEN}Configuring /etc/hosts...${NC}"
if ! grep -q "gitlab.local" /etc/hosts; then
    echo -e "${YELLOW}Adding 127.0.0.1 gitlab.local to /etc/hosts...${NC}"
    echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts > /dev/null
    echo -e "${GREEN}Entry added successfully!${NC}"
else
    echo -e "${GREEN}gitlab.local already in /etc/hosts${NC}"
fi

# Display access information
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  GitLab Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}Access GitLab at:${NC} http://gitlab.local"
echo -e "${GREEN}Username:${NC} root"
echo -e "${GREEN}Password:${NC} Saved in ./bonus/GITLAB_ROOT_PASSWORD"
echo ""
echo -e "${GREEN}To view GitLab pods:${NC}"
echo "  kubectl get pods -n gitlab"
echo ""
echo -e "${GREEN}To view GitLab services:${NC}"
echo "  kubectl get svc -n gitlab"
echo ""
echo -e "${GREEN}To check GitLab logs:${NC}"
echo "  kubectl logs -l app=webservice -n gitlab"
echo ""

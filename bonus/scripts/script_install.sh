#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BONUS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
GITLAB_CONFS_DIR="${BONUS_DIR}/confs/gitlab"

# __________________Install Helm
echo -e "'\033[0;32m'Installing Helm...'\033[0m'"
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


# __________________Add GitLab Helm repo
echo -e "'\033[0;32m'Adding GitLab Helm repository...'\033[0m'"
helm repo add gitlab https://charts.gitlab.io/
helm repo update


# __________________Install GitLab
echo -e "'\033[0;32m'Installing GitLab via Helm (this takes ~5-10 min)...'\033[0m'"
helm install gitlab gitlab/gitlab \
    --namespace gitlab \
    --create-namespace \
    --values "${GITLAB_CONFS_DIR}/gitlab-values.yaml" \
    --timeout 20m \
    --wait


# __________________Wait for GitLab migrations
# __________________The migrations job creates the root user and seeds the database.
# __________________The webservice can start before migrations finish, so we wait for the job.
echo -e "'\033[0;32m'Waiting for GitLab migrations to complete...'\033[0m'"
kubectl wait --for=condition=complete job -l app=migrations -n gitlab --timeout=600s


# __________________Apply GitLab ingress
echo -e "'\033[0;32m'Applying GitLab ingress...'\033[0m'"
kubectl apply -f "${GITLAB_CONFS_DIR}/gitlab-ingress.yaml"


# __________________Save root password
echo -e "'\033[0;32m'Saving GitLab root password...'\033[0m'"
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
    -o jsonpath="{.data.password}" | base64 -d > "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD"
echo ""
echo -e "'\033[0;32m'Password saved to bonus/GITLAB_ROOT_PASSWORD'\033[0m'"


# __________________Add entries to /etc/hosts
echo -e "'\033[0;32m'Adding hosts to /etc/hosts...'\033[0m'"
echo "127.0.0.1 gitlab.local"  | sudo tee -a /etc/hosts


# __________________Wait for GitLab API
# __________________The webservice pod can be Running while GitLab is still initializing internally.
# __________________We wait until the API responds 200 or 400 code before the ArgoCD integration.
echo -e "'\033[0;32m'Waiting for GitLab API to be ready...'\033[0m'"
until curl -s -o /dev/null -w "%{http_code}" http://gitlab.local/api/v4/version | grep -q "200\|401"; do
    echo "  GitLab API not ready yet, retrying in 10s..."
    sleep 10
done
echo -e "'\033[0;32m'GitLab API is ready.'\033[0m'"


# __________________Run ArgoCD integration
echo -e "'\033[0;32m'Running ArgoCD integration...'\033[0m'"
bash "${SCRIPT_DIR}/script_argocd_integration.sh"


echo -e "'\033[0;32m'Done! GitLab is available at http://gitlab.local'\033[0m'"
echo -e "'\033[0;32m'Root password: $(cat "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD")'\033[0m'"
echo -e "'\033[0;32m'Done! ArgoCD is available at http://argocd.local'\033[0m'"
echo -e "'\033[0;32m'admin password: $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d | cat)'\033[0m'"


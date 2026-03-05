#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GITLAB_URL="http://gitlab.local"
GITLAB_INTERNAL="http://gitlab-webservice-default.gitlab.svc.cluster.local:8181"
DEPLOY_SRC="${REPO_ROOT}/Inception-project/deployment"

# ── 1. Load GitLab root password ─────────────────────────────────────────────

echo -e "${GREEN}Loading GitLab root password...${NC}"
GITLAB_PASSWORD=$(cat "${SCRIPT_DIR}/GITLAB_ROOT_PASSWORD" | tr -d '\n')

# ── 2. Create a personal access token ────────────────────────────────────────
# Use the admin API endpoint with HTTP basic auth (root:password).
# The token is saved to GITLAB_API_TOKEN for use in later steps.

echo -e "${GREEN}Creating GitLab personal access token...${NC}"
GITLAB_TOKEN=$(curl -s --request POST \
    "${GITLAB_URL}/api/v4/users/1/personal_access_tokens" \
    --user "root:${GITLAB_PASSWORD}" \
    --header 'Content-Type: application/json' \
    --data '{"name":"argocd-token","scopes":["api","read_repository","write_repository"],"expires_at":"2030-01-01"}' \
    | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "${RED}Failed to create token. Is GitLab reachable at ${GITLAB_URL}?${NC}"
    exit 1
fi

echo "$GITLAB_TOKEN" > "${SCRIPT_DIR}/GITLAB_API_TOKEN"
echo -e "${GREEN}Token saved to bonus/GITLAB_API_TOKEN${NC}"

# ── 3. Create the wil-app project on GitLab ──────────────────────────────────
# There is no git command to create a project on GitLab, so we use the API.

echo -e "${GREEN}Creating wil-app project on GitLab...${NC}"
curl -s --request POST "${GITLAB_URL}/api/v4/projects" \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --data "name=wil-app&visibility=public" \
    > /dev/null

# ── 4. Push deployment files to GitLab ───────────────────────────────────────
# Init a local git repo, copy the files, then push to GitLab.
# No need to clone since the remote repo is empty (no initialize_with_readme).
# The token is embedded in the URL for authentication (no interactive prompt).

echo -e "${GREEN}Pushing deployment files from ${DEPLOY_SRC}...${NC}"

git init /tmp/wil-app
cd /tmp/wil-app
git remote add origin "http://root:${GITLAB_TOKEN}@gitlab.local/root/wil-app.git"
git config user.email "root@gitlab.local"
git config user.name "root"

mkdir -p deployment
cp "${DEPLOY_SRC}"/*.yaml deployment/

git add .
git commit -m "Add deployment files"
git push -u origin main

cd "${SCRIPT_DIR}"
rm -rf /tmp/wil-app

# ── 5. Reinstall ArgoCD ───────────────────────────────────────────────────────
# Delete the ArgoCD namespace from P3 and recreate it fresh.
# Then reinstall ArgoCD and reconfigure it to use --insecure (HTTP access).

echo -e "${GREEN}Deleting ArgoCD namespace from P3...${NC}"
kubectl delete namespace argocd --ignore-not-found

echo -e "${GREEN}Reinstalling ArgoCD...${NC}"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
kubectl patch deployment argocd-server -n argocd --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd

# ── 6. Apply ArgoCD manifests ────────────────────────────────────────────────
# argocd-basic.yaml  : ArgoCD Application pointing to the local GitLab repo
# argocd-ingress.yaml: Exposes ArgoCD at http://argocd.local
# gitlab-repo-secret : Credentials for ArgoCD to clone the GitLab repo
#                      (sed injects the token generated at step 2)

echo -e "${GREEN}Applying ArgoCD manifests...${NC}"
kubectl apply -f "${SCRIPT_DIR}/argocd/argocd-basic.yaml"
kubectl apply -f "${SCRIPT_DIR}/argocd/argocd-ingress.yaml"
sed "s/GITLAB_TOKEN_PLACEHOLDER/${GITLAB_TOKEN}/" "${SCRIPT_DIR}/argocd/gitlab-repo-secret.yaml" | kubectl apply -f -

echo -e "${GREEN}Done! ArgoCD is now syncing from: ${GITLAB_INTERNAL}/root/wil-app.git${NC}"
echo -e "${GREEN}Check status with: kubectl get applications -n argocd${NC}"

#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GITLAB_URL="http://gitlab.local"
GITLAB_INTERNAL="http://gitlab-webservice-default.gitlab.svc.cluster.local:8181"
DEPLOY_SRC="${SCRIPT_DIR}/gitlab/repository"


# __________________Create a gitlab personal access token directly in the pod
# __________________Ruby framework script to get root user and create a token with permissions using scop
echo -e "'\033[0;32m'Creating GitLab personal access token...'\033[0m'"
EXPIRY=$(date -d "+1 year" +%Y-%m-%d)
RUBY_SCRIPT="token = User.find_by_username('root').personal_access_tokens.create(name: 'argocd-token', scopes: ['api','read_repository','write_repository'], expires_at: '${EXPIRY}'); puts token.token"
GITLAB_TOKEN=$(kubectl exec -n gitlab deploy/gitlab-toolbox -- gitlab-rails runner "$RUBY_SCRIPT")

if [ -z "$GITLAB_TOKEN" ]; then
    echo -e "'\033[0;31m'Failed to create token.'\033[0m'"
    exit 1
fi

echo "$GITLAB_TOKEN" > "${SCRIPT_DIR}/GITLAB_API_TOKEN"
echo -e "'\033[0;32m'Token saved to bonus/GITLAB_API_TOKEN'\033[0m'"


# __________________Create the wil-app project on GitLab
# __________________No git command to create a GitLab project, so use the API.
# __________________API POST is for ressource creation, auth with GITLAB_TOKEN then data contain gitlab informations
echo -e "'\033[0;32m'Creating wil-app project on GitLab...'\033[0m'"
curl -s --request POST "${GITLAB_URL}/api/v4/projects" \
    --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    --data "name=wil-app&visibility=public" \
    > /dev/null


# __________________Create and Push files to GitLab repository
echo -e "'\033[0;32m'Pushing deployment files from ${DEPLOY_SRC}...'\033[0m'"
# __________________Init a local git repo in /gitlab/repository & set-up git ingo
cd "${DEPLOY_SRC}"
git init -b main .
git remote add origin "http://root:${GITLAB_TOKEN}@gitlab.local/root/wil-app.git"
git config user.email "root@gitlab.local"
git config user.name "root"
# __________________Add then push the files already present in the current directory to GitLab.
git add .
git commit -m "Add deployment files"
git push -u origin main
cd "${SCRIPT_DIR}"


# __________________Reinstall ArgoCD with Gitlab
# __________________Delete the ArgoCD namespace from P3 and recreate it fresh.
echo -e "'\033[0;32m'Deleting ArgoCD namespace from P3...'\033[0m'"
kubectl delete namespace argocd --ignore-not-found
# __________________Then reinstall ArgoCD and reconfigure it to use --insecure (HTTP access).
echo -e "'\033[0;32m'Reinstalling ArgoCD...'\033[0m'"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
# __________________Here ↓↓↓↓ is the Argocd reconfiguration without HTTP
kubectl patch deployment argocd-server -n argocd --type='json' \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]'
kubectl rollout status deployment/argocd-server -n argocd


# __________________Apply ArgoCD manifests
echo -e "'\033[0;32m'Applying ArgoCD manifests...'\033[0m'"
kubectl apply -f "${SCRIPT_DIR}/argocd/argocd-basic.yaml"
kubectl apply -f "${SCRIPT_DIR}/argocd/argocd-ingress.yaml"
# __________________sed injects the token generated at step 2
sed "s/GITLAB_TOKEN_PLACEHOLDER/${GITLAB_TOKEN}/" "${SCRIPT_DIR}/argocd/gitlab-repo-secret.yaml" | kubectl apply -f -


echo -e "'\033[0;32m'Done! ArgoCD is now syncing from: ${GITLAB_INTERNAL}/root/wil-app.git'\033[0m'"
echo -e "'\033[0;32m'Check status with: kubectl get applications -n argocd'\033[0m'"

#!/bin/bash

set -e

echo "========================================="
echo "   Starting bonus installation...        "
echo "========================================="

# ─── 1. DOCKER ───────────────────────────────
echo "[1/8] Installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker.io curl git

echo "Starting and enabling Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# ─── 2. K3D ──────────────────────────────────
echo "[2/8] Installing K3d..."
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# ─── 3. KUBECTL ──────────────────────────────
echo "[3/8] Installing kubectl..."
KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# ─── 4. HELM ─────────────────────────────────
echo "[4/8] Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ─── 5. CLUSTER K3D ──────────────────────────
echo "[5/8] Creating k3d cluster..."
sudo docker ps > /dev/null 2>&1
sudo k3d cluster delete bonus-cluster 2>/dev/null || true
sudo k3d cluster create bonus-cluster \
	--agents 3 \
	--servers 1 \
	--k3s-arg "--kubelet-arg=eviction-hard=memory.available<500Mi@agent:*" \
	--k3s-arg "--kubelet-arg=eviction-hard=memory.available<500Mi@server:0" \
	--wait

mkdir -p ~/.kube
sudo k3d kubeconfig get bonus-cluster > ~/.kube/config
chmod 600 ~/.kube/config

echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# ─── 6. NAMESPACES ───────────────────────────
echo "[6/8] Creating namespaces..."
kubectl create namespace argocd 2>/dev/null || true
kubectl create namespace gitlab 2>/dev/null || true
kubectl create namespace dev    2>/dev/null || true

# ─── 7. ARGO CD ──────────────────────────────
echo "[7/8] Installing Argo CD..."
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for Argo CD to be ready..."
kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=300s

echo "Installing Argo CD CLI..."
ARGOCD_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-cd/releases/latest \
  | grep tag_name | cut -d '"' -f4)
curl -sSL -o argocd \
  "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
chmod +x argocd
sudo mv argocd /usr/local/bin/argocd

# ─── 8. GITLAB ───────────────────────────────
echo "[8/8] Installing GitLab with Helm (5-10 minutes)..."
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --set global.hosts.domain=gitlab.local \
  --set global.hosts.externalIP=127.0.0.1 \
  --set global.hosts.https=false \
  --set global.edition=ce \
  --set certmanager.enabled=false \
  --set certmanager-issuer.email=admin@gitlab.local \
  --set nginx-ingress.enabled=false \
  --set prometheus.install=false \
  --set gitlab-runner.install=false \
  --set global.ingress.enabled=false \
  --set gitlab.webservice.replicaCount=1 \
  --set gitlab.sidekiq.replicaCount=1 \
  --timeout 600s

echo "Waiting for GitLab to be ready..."
kubectl wait --for=condition=ready pod \
  -l app=webservice \
  -n gitlab \
  --timeout=600s

# ─── EXPOSE GITLAB ────────────────────────────
echo "Exposing GitLab..."
kubectl port-forward svc/gitlab-webservice-default \
  -n gitlab 8181:8080 &
PORTFORWARD_PID=$!
sleep 15

# ─── GITLAB PASSWORD & REPO ──────────────────
echo "Getting GitLab root password..."
GITLAB_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password \
  -n gitlab \
  -o jsonpath="{.data.password}" | base64 -d)

echo "Creating GitLab API token..."
GITLAB_TOKEN=$(curl -s -X POST "http://localhost:8181/api/v4/users/1/personal_access_tokens" \
  --header "Content-Type: application/json" \
  --user "root:$GITLAB_PASSWORD" \
  --data '{
    "name": "argo-token",
    "scopes": ["api", "read_repository", "write_repository"]
  }' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

echo "Creating GitLab repository..."
curl -s -X POST "http://localhost:8181/api/v4/projects" \
  --header "Content-Type: application/json" \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --data '{
    "name": "inception-of-things",
    "visibility": "public",
    "initialize_with_readme": false
  }'

# ─── CREATE MANIFESTS ────────────────────────
echo "Creating Kubernetes manifests..."
mkdir -p /tmp/iot-confs/confs

cat <<EOF > /tmp/iot-confs/confs/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: playground
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: playground
  template:
    metadata:
      labels:
        app: playground
    spec:
      containers:
      - name: playground
        image: wil42/playground:v1
        ports:
        - containerPort: 8888
---
apiVersion: v1
kind: Service
metadata:
  name: playground-service
  namespace: dev
spec:
  selector:
    app: playground
  ports:
  - port: 8888
    targetPort: 8888
  type: ClusterIP
EOF

cat <<EOF > /tmp/iot-confs/confs/argocd-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: playground-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local:8080/root/inception-of-things.git
    targetRevision: main
    path: confs
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# ─── PUSH TO GITLAB ──────────────────────────
echo "Pushing code to GitLab local..."
cd /tmp/iot-confs
git init
git config user.email "admin@gitlab.local"
git config user.name "admin"
git add .
git commit -m "initial commit"
git remote add origin http://root:${GITLAB_PASSWORD}@localhost:8181/root/inception-of-things.git
git push -u origin main
cd -

# ─── CONFIGURE ARGO CD → GITLAB ──────────────
echo "Configuring Argo CD to use GitLab local..."

kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitlab-webservice-default.gitlab.svc.cluster.local:8080/root/inception-of-things.git
  username: root
  password: ${GITLAB_PASSWORD}
EOF

kubectl apply -f /tmp/iot-confs/confs/argocd-app.yaml

# ─── WAIT FOR APP ────────────────────────────
echo "Waiting for playground app to be deployed..."
kubectl wait --for=condition=ready pod \
  -l app=playground \
  -n dev \
  --timeout=300s

# ─── DONE ────────────────────────────────────
kill $PORTFORWARD_PID 2>/dev/null || true

echo ""
echo "========================================="
echo "   Installation complete!                "
echo "========================================="
echo ""
echo "GitLab URL     : http://localhost:8181"
echo "GitLab user    : root"
echo "GitLab password: ${GITLAB_PASSWORD}"
echo ""
echo "Argo CD admin password:"
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 --decode
echo ""
echo ""
echo "To access Argo CD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then open: https://localhost:8080"
echo ""
echo "To access GitLab UI:"
echo "  kubectl port-forward svc/gitlab-webservice-default -n gitlab 8181:8080"
echo "  Then open: http://localhost:8181"
echo ""
echo "To test GitOps:"
echo "  1. git clone http://root:${GITLAB_PASSWORD}@localhost:8181/root/inception-of-things.git"
echo "  2. Edit confs/deployment.yaml (v1 → v2)"
echo "  3. git push → Argo CD auto-deploys!"
echo ""
echo "NOTE: Log out and back in (or run 'newgrp docker') for docker group to take effect."

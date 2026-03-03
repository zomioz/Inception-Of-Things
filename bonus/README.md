# Bonus - GitLab Integration

This bonus part adds a local GitLab instance to the Inception-Of-Things project, integrating it with the ArgoCD setup from Part 3.

## Overview

GitLab serves as a self-hosted Git repository platform that integrates with ArgoCD for GitOps workflows. Instead of using external repositories (GitHub, etc.), everything runs locally in your Kubernetes cluster.

## Architecture

```
GitLab (local) → ArgoCD → Kubernetes Cluster
    ↓
Git Repositories
    ↓
Application Manifests
```

## Requirements

- Completed Part 3 (ArgoCD setup)
- Kubernetes cluster running (k3d)
- Helm 3.x
- Minimum 4GB RAM available
- kubectl configured

## Installation

### 1. Install GitLab

Run the installation script:

```bash
cd /path/to/Inception-Of-Things
chmod +x bonus/script_install.sh
./bonus/script_install.sh
```

This script will:
- Check prerequisites (kubectl, cluster)
- Install Helm if not present
- Create `gitlab` namespace
- Deploy GitLab with minimal configuration
- Retrieve root password

### 2. Access GitLab

After installation, add to `/etc/hosts`:

```
127.0.0.1 gitlab.local
```

Access GitLab:
- URL: http://gitlab.local
- Username: `root`
- Password: Check `bonus/GITLAB_ROOT_PASSWORD`

### 3. Configure GitLab for ArgoCD

1. Create a new project in GitLab
2. Push your application manifests
3. Update ArgoCD to point to GitLab repository

## Configuration

### Minimal Resources

GitLab is configured with minimal resources to run on limited hardware:

- PostgreSQL: 256Mi - 512Mi RAM
- Redis: 128Mi - 256Mi RAM
- Webservice: 512Mi - 1Gi RAM
- Gitaly: 256Mi - 512Mi RAM
- Sidekiq: 512Mi - 1Gi RAM

**Total estimated RAM usage: ~2-3GB**

### Disabled Components

To save resources, the following are disabled:
- GitLab Runner (CI/CD)
- Prometheus (monitoring)
- Grafana (dashboards)
- Minio (object storage)
- Container Registry
- GitLab Pages
- Kubernetes Agent Server

## Uninstallation

To completely remove GitLab:

```bash
chmod +x bonus/script_uninstall.sh
./bonus/script_uninstall.sh
```

This will:
- Uninstall Helm release
- Delete gitlab namespace
- Remove all persistent data
- Clean up password file

## Verification

Check GitLab pods:
```bash
kubectl get pods -n gitlab
```

Check GitLab services:
```bash
kubectl get svc -n gitlab
```

View logs:
```bash
kubectl logs -l app=webservice -n gitlab
```

## Troubleshooting

### GitLab pods not starting
- Check available resources: `kubectl top nodes`
- Increase resource limits in `gitlab-values.yaml`

### Cannot access gitlab.local
- Verify /etc/hosts entry
- Check ingress: `kubectl get ingress -n gitlab`

### Out of memory errors
- Reduce replica counts to 1
- Reduce memory limits in values file
- Close other applications

## Integration with ArgoCD

See the configuration files in `argocd/` directory for connecting ArgoCD to your local GitLab instance.

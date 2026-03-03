# Notes d'installation GitLab - Bonus IoT

## 📋 Contexte

Ce document résume le travail effectué pour le bonus du projet Inception-Of-Things.
Le bonus consiste à installer GitLab localement et l'intégrer avec ArgoCD (P3).

---

## ⚠️ Prérequis IMPORTANT

### Espace disque requis
**MINIMUM : 40 GB d'espace disque libre**

Détail :
- Images Docker GitLab : ~8-10 GB
- PostgreSQL PVC : 8 GB
- Gitaly (repos Git) PVC : 10 GB  
- ArgoCD + K8s : ~2-3 GB
- Marge de sécurité : ~10 GB

**Sur l'ancienne VM** : Seulement 19 GB total → Insuffisant ❌
**Sur la nouvelle VM** : Prévoir 50-100 GB → OK ✅

### Ressources RAM
- **Recommandé : 8 GB RAM minimum**
- GitLab utilisera ~2-3 GB
- ArgoCD + K8s : ~1.5 GB
- Système : ~1-2 GB

---

## 📁 Fichiers créés

Tous les fichiers nécessaires sont dans `/bonus/` :

```
bonus/
├── script_install.sh         # Installation automatique de GitLab
├── script_uninstall.sh       # Désinstallation complète
├── gitlab-values.yaml        # Configuration Helm pour GitLab minimal
├── README.md                 # Documentation utilisateur
└── INSTALL_NOTES.md          # Ce fichier (notes techniques)
```

---

## 🚀 Étapes d'installation sur la NOUVELLE VM

### 1. Transférer les fichiers

```bash
# Sur la nouvelle VM, cloner/copier votre repo
git clone <votre-repo> Inception-Of-Things
cd Inception-Of-Things
```

Ou copier manuellement le dossier `bonus/` depuis l'ancienne VM.

### 2. Vérifier l'espace disque

```bash
df -h /
# Doit montrer au moins 40 GB libres
```

### 3. Installer P3 d'abord (si pas déjà fait)

```bash
cd /path/to/Inception-Of-Things
./P3/script_install.sh
```

Attendre que ArgoCD soit complètement opérationnel.

### 4. Installer GitLab

```bash
cd /path/to/Inception-Of-Things
chmod +x bonus/script_install.sh
./bonus/script_install.sh
```

Le script va :
- ✅ Vérifier les prérequis (kubectl, cluster, Traefik)
- ✅ Vérifier la RAM disponible (alerte si >85%)
- ✅ Installer Helm si absent
- ✅ Créer le namespace `gitlab`
- ✅ Déployer GitLab avec configuration minimale
- ✅ Ajouter `gitlab.local` à `/etc/hosts`
- ✅ Récupérer le mot de passe root

**Durée** : 10-15 minutes

### 5. Accéder à GitLab

```bash
# Le mot de passe est dans :
cat ./bonus/GITLAB_ROOT_PASSWORD
```

Ouvrir dans le navigateur : http://gitlab.local
- Username : `root`
- Password : (voir fichier ci-dessus)

---

## 🔧 Configuration GitLab actuelle

### Composants activés
- ✅ PostgreSQL (DB) : 256-512 Mi RAM, 8 Gi disk
- ✅ Redis (Cache) : 128-256 Mi RAM
- ✅ Webservice (Interface) : 512 Mi-1 Gi RAM
- ✅ Gitaly (Git storage) : 256-512 Mi RAM, 10 Gi disk
- ✅ Sidekiq (Jobs) : 512 Mi-1 Gi RAM
- ✅ GitLab Shell : 128-256 Mi RAM

### Composants désactivés (pour économiser)
- ❌ GitLab Runner (CI/CD)
- ❌ Prometheus/Grafana (monitoring)
- ❌ Container Registry
- ❌ GitLab Pages

**Note** : Certains composants (certmanager, minio, kas) se déploient automatiquement malgré `enabled: false` car le chart GitLab les considère comme dépendances.

### Ressources totales estimées
- RAM : ~2-3 GB
- Disk : ~18-20 GB
- CPU : ~1-2 cores

---

## 🐛 Problèmes rencontrés et solutions

### Erreur 1 : `certmanager: additional properties 'install' not allowed`
**Solution** : Utiliser `enabled: false` au lieu de `install: false`

### Erreur 2 : `You must provide an email... certmanager-issuer.email`
**Solution** : Ajouter un email factice même quand désactivé :
```yaml
certmanager-issuer:
  enabled: false
  email: admin@gitlab.local
```

### Erreur 3 : Espace disque insuffisant (ancienne VM)
**Solution** : Créer nouvelle VM avec 50-100 GB

---

## ✅ Vérifications post-installation

### 1. Vérifier les pods
```bash
kubectl get pods -n gitlab
# Tous doivent être Running
```

### 2. Vérifier les services
```bash
kubectl get svc -n gitlab
```

### 3. Vérifier l'ingress
```bash
kubectl get ingress -n gitlab
# Doit montrer gitlab.local
```

### 4. Tester l'accès web
```bash
curl -I http://gitlab.local
# Doit retourner HTTP 200 ou 302
```

### 5. Vérifier les ressources
```bash
kubectl top pods -n gitlab
kubectl top nodes
```

---

## 🔗 Intégration avec ArgoCD (Prochaine étape)

Une fois GitLab installé et fonctionnel :

### 1. Créer un projet dans GitLab
- Se connecter à http://gitlab.local
- Créer un nouveau projet : "wil-app"
- Obtenir l'URL : `http://gitlab-webservice-default.gitlab.svc.cluster.local/root/wil-app.git`

### 2. Créer un token d'accès
- GitLab → Settings → Access Tokens
- Nom : "ArgoCD"
- Scopes : `read_repository`, `write_repository`
- Copier le token généré

### 3. Configurer ArgoCD pour utiliser GitLab
Créer un fichier `bonus/argocd/gitlab-integration.yaml` :

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitlab-webservice-default.gitlab.svc.cluster.local/root/wil-app.git
  password: <TOKEN>
  username: root
```

Appliquer :
```bash
kubectl apply -f bonus/argocd/gitlab-integration.yaml
```

### 4. Créer une Application ArgoCD pointant vers GitLab
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: wil-app-gitlab
  namespace: argocd
spec:
  project: default
  source:
    repoURL: http://gitlab-webservice-default.gitlab.svc.cluster.local/root/wil-app.git
    targetRevision: main
    path: deployment
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## 🗑️ Désinstallation

Pour tout supprimer :

```bash
cd /path/to/Inception-Of-Things
./bonus/script_uninstall.sh
```

Le script supprime :
- La release Helm GitLab
- Le namespace `gitlab` (et tout son contenu)
- Les PVCs (données persistantes)
- L'entrée `gitlab.local` dans `/etc/hosts`
- Le repo Helm GitLab

---

## 📊 Architecture finale

```
┌─────────────────────────────────────────────────────┐
│                    Utilisateur                      │
└──────────────┬──────────────────────┬───────────────┘
               │                      │
        http://gitlab.local    http://argocd.local
               │                      │
               ▼                      ▼
        ┌──────────────┐      ┌──────────────┐
        │   GitLab     │      │   ArgoCD     │
        │  (namespace  │◄─────│  (namespace  │
        │   gitlab)    │ Poll │   argocd)    │
        └──────────────┘      └──────┬───────┘
               │                     │
        Stocke repos Git       Déploie apps
               │                     │
               ▼                     ▼
        ┌──────────────────────────────────────┐
        │      Kubernetes Cluster (k3d)        │
        │  Namespaces: dev, gitlab, argocd     │
        └──────────────────────────────────────┘
```

---

## 🎓 Explications pour la soutenance

### Pourquoi GitLab ?
- **GitOps complet** : Source de vérité locale pour ArgoCD
- **Autonomie** : Pas de dépendance externe (GitHub, etc.)
- **Réaliste** : Simule un environnement d'entreprise

### Composants essentiels
- **PostgreSQL** : Stocke metadata (users, projects, permissions)
- **Redis** : Cache et sessions
- **Gitaly** : Gère les opérations Git (clone, push, pull)
- **Webservice** : Interface web + API REST pour ArgoCD
- **Sidekiq** : Tâches asynchrones (création repos, indexation)

### Workflow GitOps
1. Développeur → `git push` → GitLab
2. ArgoCD → Poll GitLab toutes les 3 min
3. ArgoCD détecte changement → `kubectl apply`
4. Application mise à jour automatiquement

---

## 📞 Commandes utiles

```bash
# Voir les logs GitLab
kubectl logs -l app=webservice -n gitlab -f

# Redémarrer GitLab
kubectl rollout restart deployment -n gitlab

# Vérifier l'état de Helm
helm list -n gitlab

# Vérifier les PVCs
kubectl get pvc -n gitlab

# Accéder au shell d'un pod GitLab
kubectl exec -it <pod-name> -n gitlab -- /bin/bash

# Récupérer à nouveau le mot de passe
kubectl get secret gitlab-gitlab-initial-root-password -n gitlab \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## ✨ Optimisations possibles (si plus de ressources)

Si votre nouvelle VM a beaucoup de RAM/CPU/Disk, vous pouvez :

### Augmenter les ressources
```yaml
# Dans gitlab-values.yaml
webservice:
  resources:
    requests:
      memory: 1Gi
    limits:
      memory: 2Gi
```

### Activer des composants supplémentaires
```yaml
# Monitoring
prometheus:
  install: true

# Container Registry
registry:
  enabled: true

# CI/CD
gitlab-runner:
  install: true
```

### Augmenter le stockage
```yaml
postgresql:
  persistence:
    size: 20Gi  # Au lieu de 8Gi

gitaly:
  persistence:
    size: 50Gi  # Au lieu de 10Gi
```

---

## 📅 Résumé de la session

**Travail effectué** :
1. ✅ Analyse du sujet bonus
2. ✅ Explication de GitLab et son rôle avec ArgoCD
3. ✅ Création de la configuration minimale (`gitlab-values.yaml`)
4. ✅ Création des scripts d'installation/désinstallation
5. ✅ Vérification des dépendances avec P3
6. ✅ Corrections des erreurs Helm (certmanager, email)
7. ✅ Détection du problème d'espace disque
8. ✅ Documentation complète

**Décision** : Créer nouvelle VM avec plus d'espace (50-100 GB)

**Prochaines étapes** sur la nouvelle VM :
1. Installer P3
2. Installer GitLab (bonus/)
3. Configurer l'intégration ArgoCD ↔ GitLab
4. Tester le workflow GitOps complet

---

**Date** : 3 mars 2026
**VM actuelle** : 19 GB total (insuffisant)
**Nouvelle VM** : 50-100 GB (recommandé)

Bonne chance avec la nouvelle VM ! 🚀

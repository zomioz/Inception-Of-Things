# Spécifications requises pour la nouvelle VM

## 💾 Stockage
**MINIMUM : 50 GB**
**RECOMMANDÉ : 80-100 GB**

### Répartition de l'espace :
```
Système d'exploitation     : ~10 GB
Docker images              : ~10 GB
P3 (ArgoCD + K8s)          : ~3 GB
GitLab images              : ~8 GB
PostgreSQL (data)          : 15 GB (configuré)
Gitaly (repos Git)         : 20 GB (configuré)
Marge de sécurité          : ~10 GB
───────────────────────────────────
TOTAL                      : ~76 GB
```

## 🧠 RAM
**MINIMUM : 8 GB**
**RECOMMANDÉ : 12-16 GB**

### Utilisation estimée :
```
Système                    : ~1 GB
ArgoCD                     : ~300 MB
GitLab (total)             : ~2-3 GB
  - PostgreSQL             : ~512 MB
  - Redis                  : ~256 MB
  - Webservice             : ~1 GB
  - Gitaly                 : ~512 MB
  - Sidekiq                : ~1 GB
  - Autres composants      : ~500 MB
Marge                      : ~2 GB
───────────────────────────────────
TOTAL                      : ~5-6 GB
```

## 🖥️ CPU
**MINIMUM : 2 cores**
**RECOMMANDÉ : 4 cores**

### Utilisation :
- Pics lors du déploiement : ~2 cores
- Utilisation normale : ~0.5-1 core

## 🌐 Configuration réseau
- Accès Internet requis (pour télécharger images Docker et Helm charts)
- Port 80/443 disponible
- Pas de proxy restrictif

## 📦 Système d'exploitation
**Recommandé** : Ubuntu 22.04 LTS ou Debian 11+

**Packages à vérifier** :
```bash
# Installés par les scripts P3/bonus
- docker.io
- kubectl
- k3d
- helm
```

## ⚙️ Configuration VM (exemple VirtualBox)

```
Nom                : inception-of-things
Type               : Linux
Version            : Ubuntu (64-bit)
Mémoire            : 12288 MB (12 GB)
Processeurs        : 4 CPUs
Vidéo              : 128 MB
Disque dur         : 80 GB (dynamiquement alloué)
Réseau Adaptateur 1: NAT ou Bridged
```

## 📋 Vérification post-création

Après avoir créé la nouvelle VM :

```bash
# 1. Vérifier l'espace disque
df -h /
# Attendu : ~70-80 GB disponibles

# 2. Vérifier la RAM
free -h
# Attendu : ~12 GB total

# 3. Vérifier les cores
nproc
# Attendu : 4

# 4. Vérifier la connexion Internet
ping -c 4 google.com

# 5. Mettre à jour le système
sudo apt update && sudo apt upgrade -y
```

## 🔄 Transfert des fichiers

### Option 1 : Git (recommandé)
```bash
# Sur nouvelle VM
git clone <votre-repo> Inception-Of-Things
cd Inception-Of-Things
```

### Option 2 : SCP
```bash
# Depuis ancienne VM vers nouvelle
scp -r bonus/ user@nouvelle-vm:/path/to/Inception-Of-Things/
```

### Option 3 : Copie manuelle
- Copier le dossier `bonus/` complet
- Vérifier que tous les fichiers sont présents

## ✅ Récapitulatif

| Ressource | Ancienne VM | Nouvelle VM | Status |
|-----------|-------------|-------------|--------|
| Disque    | 19 GB       | 80 GB       | ✅ OK  |
| RAM       | ?           | 12 GB       | ✅ OK  |
| CPU       | ?           | 4 cores     | ✅ OK  |

**La nouvelle VM sera parfaite pour GitLab !** 🎉

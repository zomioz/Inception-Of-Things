#!/bin/bash

# ============================================
# REPRISE RAPIDE SUR LA NOUVELLE VM
# ============================================

echo "🚀 Checklist de reprise sur la nouvelle VM"
echo ""

echo "1️⃣  Vérifier l'espace disque"
echo "   Commande : df -h /"
echo "   Attendu  : Au moins 40-50 GB libres"
echo ""

echo "2️⃣  Vérifier que tous les fichiers bonus/ sont présents"
echo "   - script_install.sh"
echo "   - script_uninstall.sh"
echo "   - gitlab-values.yaml"
echo "   - README.md"
echo "   - INSTALL_NOTES.md (documentation complète)"
echo ""

echo "3️⃣  Installer P3 d'abord"
echo "   cd /path/to/Inception-Of-Things"
echo "   ./P3/script_install.sh"
echo "   Attendre que ArgoCD soit prêt (~5 min)"
echo ""

echo "4️⃣  Vérifier ArgoCD"
echo "   kubectl get pods -n argocd"
echo "   Tous doivent être Running"
echo ""

echo "5️⃣  Installer GitLab (bonus)"
echo "   chmod +x bonus/script_install.sh"
echo "   ./bonus/script_install.sh"
echo "   Durée : ~10-15 minutes"
echo ""

echo "6️⃣  Accéder à GitLab"
echo "   URL      : http://gitlab.local"
echo "   Username : root"
echo "   Password : cat bonus/GITLAB_ROOT_PASSWORD"
echo ""

echo "📖 Pour plus de détails, voir : bonus/INSTALL_NOTES.md"
echo ""

# Afficher l'état actuel si exécuté
if command -v kubectl &> /dev/null; then
    echo "════════════════════════════════════════"
    echo "État actuel du cluster :"
    echo "════════════════════════════════════════"
    
    if kubectl cluster-info &> /dev/null; then
        echo "✅ Cluster K8s : Running"
        
        if kubectl get namespace argocd &> /dev/null; then
            echo "✅ ArgoCD installé"
        else
            echo "⏳ ArgoCD non installé"
        fi
        
        if kubectl get namespace gitlab &> /dev/null; then
            echo "✅ GitLab installé"
        else
            echo "⏳ GitLab non installé"
        fi
    else
        echo "❌ Cluster K8s non accessible"
    fi
fi

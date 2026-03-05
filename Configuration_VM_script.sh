#!/bin/bash

# =========================================================================
# Inception-Of-Things - Complete VM Setup Script
# For Debian 12 Bookworm64
# =========================================================================
# This script installs all necessary dependencies for P1, P2, P3, and Bonus

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
set -e
trap 'echo -e "${RED}Error occurred at line $LINENO${NC}"' ERR

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Inception-Of-Things Setup Script${NC}"
echo -e "${BLUE}  Debian 12 Bookworm64${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}This script installs base requirements:${NC}"
echo -e "  • For P1/P2: VirtualBox + Vagrant"
echo -e "  • For P3/Bonus: Base tools (P3 script will install docker/kubectl/k3d/helm)"
echo -e "  • Git, SSH, VS Code"
echo ""

# =========================================================================
# 1. SYSTEM UPDATE
# =========================================================================
echo -e "${GREEN}[1/8] Updating system packages...${NC}"
sudo apt-get update -y
sudo apt-get upgrade -y

# Essential packages for the project
# - ca-certificates, gnupg, wget: for secure downloads and repo keys
# - lsb-release: for detecting Debian version in scripts
# - build-essential, linux-headers, dkms: for VirtualBox kernel modules
sudo apt-get install -y \
    ca-certificates \
    gnupg \
    lsb-release \
    wget \
    build-essential \
    linux-headers-$(uname -r) \
    dkms

# =========================================================================
# 2. INSTALL CURL AND GIT
# =========================================================================
echo -e "${GREEN}[2/8] Installing curl and git...${NC}"
sudo apt-get install -y curl git

# =========================================================================
# 3. CONFIGURE GIT
# =========================================================================
echo -e "${GREEN}[3/8] Configuring git...${NC}"
git config --global user.name "zomioz"
git config --global user.email "pierrerulence@gmail.com"
echo -e "${YELLOW}Git configured:${NC}"
echo -e "  User: $(git config --global user.name)"
echo -e "  Email: $(git config --global user.email)"

# =========================================================================
# 4. GENERATE SSH KEY
# =========================================================================
echo -e "${GREEN}[4/8] Generating SSH key...${NC}"
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -C "pierrerulence@gmail.com" -f ~/.ssh/id_rsa -N ""
    echo -e "${YELLOW}SSH key generated!${NC}"
else
    echo -e "${YELLOW}SSH key already exists.${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  YOUR SSH PUBLIC KEY (add to GitHub):${NC}"
echo -e "${BLUE}========================================${NC}"
cat ~/.ssh/id_rsa.pub
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Press ENTER to continue after adding the key to your GitHub account...${NC}"
read

# =========================================================================
# 5. INSTALL VIRTUALBOX
# =========================================================================
echo -e "${GREEN}[5/8] Installing VirtualBox (for P1 & P2)...${NC}"

# Add VirtualBox repository
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

sudo apt-get update
sudo apt-get install -y virtualbox-7.0

# =========================================================================
# 6. INSTALL VAGRANT
# =========================================================================
echo -e "${GREEN}[6/8] Installing Vagrant (for P1 & P2)...${NC}"

# Download and install Vagrant
VAGRANT_VERSION="2.4.1"
wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}-1_amd64.deb
sudo dpkg -i vagrant_${VAGRANT_VERSION}-1_amd64.deb
rm vagrant_${VAGRANT_VERSION}-1_amd64.deb

# Install vagrant-vbguest plugin (optional but recommended)
echo -e "${YELLOW}Installing vagrant-vbguest plugin...${NC}"
vagrant plugin install vagrant-vbguest || true

# =========================================================================
# 7. INSTALL VS CODE
# =========================================================================
echo -e "${GREEN}[7/8] Installing Visual Studio Code...${NC}"

# Add Microsoft GPG key and repository
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

sudo apt-get update
sudo apt-get install -y code

echo -e "${YELLOW}Note: For P3, run './P3/script_install.sh' which will install:${NC}"
echo -e "  - Docker"
echo -e "  - kubectl"
echo -e "  - k3d"
echo -e "  - ArgoCD setup"
echo ""
echo -e "${YELLOW}Note: For Bonus, run './bonus/script_install.sh' which will install:${NC}"
echo -e "  - Helm (if not present)"
echo -e "  - GitLab"
echo ""

# =========================================================================
# 8. CONFIGURE /etc/hosts
# =========================================================================
echo -e "${GREEN}[8/8] Configuring /etc/hosts...${NC}"

# Backup original hosts file
sudo cp /etc/hosts /etc/hosts.backup

# Add entries for the project
if ! grep -q "app1.com" /etc/hosts; then
    echo "192.168.56.110 app1.com" | sudo tee -a /etc/hosts > /dev/null
fi

if ! grep -q "app2.com" /etc/hosts; then
    echo "192.168.56.110 app2.com" | sudo tee -a /etc/hosts > /dev/null
fi

if ! grep -q "app3.com" /etc/hosts; then
    echo "192.168.56.110 app3.com" | sudo tee -a /etc/hosts > /dev/null
fi

if ! grep -q "argocd.local" /etc/hosts; then
    echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts > /dev/null
fi

if ! grep -q "wil42.local" /etc/hosts; then
    echo "127.0.0.1 wil42.local" | sudo tee -a /etc/hosts > /dev/null
fi

if ! grep -q "gitlab.local" /etc/hosts; then
    echo "127.0.0.1 gitlab.local" | sudo tee -a /etc/hosts > /dev/null
fi

echo -e "${YELLOW}/etc/hosts configured with project domains${NC}"

# =========================================================================
# INSTALLATION COMPLETE
# =========================================================================
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${YELLOW}Installed components:${NC}"
echo -e "  ✓ Git (configured as zomioz)"
echo -e "  ✓ SSH key (id_rsa)"
echo -e "  ✓ VirtualBox 7.0"
echo -e "  ✓ Vagrant ${VAGRANT_VERSION}"
echo -e "  ✓ Visual Studio Code"
echo -e "  ✓ /etc/hosts configured"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Clone or navigate to your Inception-Of-Things repository"
echo -e "  2. ${GREEN}For P1:${NC} Run 'make p1' (uses VirtualBox + Vagrant)"
echo -e "  3. ${GREEN}For P2:${NC} Run 'make p2' (uses VirtualBox + Vagrant)"
echo -e "  4. ${GREEN}For P3:${NC} Run 'make p3' or './P3/script_install.sh'"
echo -e "      → Installs: docker, kubectl, k3d, ArgoCD"
echo -e "  5. ${GREEN}For Bonus:${NC} Run './bonus/script_install.sh' (after P3)"
echo -e "      → Installs: Helm, GitLab"
echo ""
echo -e "${YELLOW}Your SSH public key (add to GitHub):${NC}"
cat ~/.ssh/id_rsa.pub
echo ""
echo -e "${BLUE}========================================${NC}"

# No need to reboot for this simplified setup
echo -e "${GREEN}Setup complete! You can now start working on the project.${NC}"

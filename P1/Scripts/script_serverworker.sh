#!/bin/bash

apt-get update
apt install -y curl
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_START=true K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=tokentmp sh -s - --node-ip=192.168.56.111 --flannel-iface=eth1
systemctl enable k3s-agent
systemctl start k3s-agent

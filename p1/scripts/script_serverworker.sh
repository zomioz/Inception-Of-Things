#!/bin/bash

apt-get update
apt install -y curl
export Token_tmp=$(cat /tmp/Token)
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$Token_tmp sh -s - --node-ip=192.168.56.111

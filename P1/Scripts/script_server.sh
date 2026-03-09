#!/bin/bash

apt-get update
apt install -y curl
export Token_tmp=$(cat /tmp/Token)
curl -sfL https://get.k3s.io | sh -s - server --token=$Token_tmp --node-ip=192.168.56.110
sleep 5
echo "Server k3s installed"
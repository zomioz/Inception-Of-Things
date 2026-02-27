#!/bin/bash

apt-get update
apt install -y curl
curl -sfL https://get.k3s.io | sh -s - server --token=tokentmp --write-kubeconfig-mode=644 --node-ip=192.168.56.110 --advertise-address=192.168.56.110 --flannel-iface=eth1

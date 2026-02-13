#!/bin/bash

apt-get update
apt install -y curl
curl -sfL https://get.k3s.io | sh -s - server --token=tokentmp --write-kubeconfig-mode=644 --node-ip=192.168.56.110

sleep 10
kubectl apply -f /tmp/manifests/app1-deployment.yaml
kubectl apply -f /tmp/manifests/app1-service.yaml
kubectl apply -f /tmp/manifests/app1-expose.yaml

kubectl apply -f /tmp/manifests/app2-deployment.yaml
kubectl apply -f /tmp/manifests/app2-service.yaml
kubectl apply -f /tmp/manifests/app2-expose.yaml
#!/bin/bash

apt-get update
apt install -y curl
curl -sfL https://get.k3s.io | sh -s - server --token=tokentmp --write-kubeconfig-mode=644 --node-ip=192.168.56.110

echo "Waiting for K3s to be ready..."
until kubectl get nodes &>/dev/null; do
  echo "K3s not ready yet, waiting..."
  sleep 2
done
echo "K3s is ready!"

sleep 5

kubectl apply -f /tmp/manifests/app1/app1-deployment.yaml
kubectl apply -f /tmp/manifests/app1/app1-service.yaml
kubectl apply -f /tmp/manifests/app1/app1-expose.yaml

kubectl apply -f /tmp/manifests/app2/app2-deployment.yaml
kubectl apply -f /tmp/manifests/app2/app2-service.yaml
kubectl apply -f /tmp/manifests/app2/app2-expose.yaml

kubectl apply -f /tmp/manifests/app3/app3-deployment.yaml
kubectl apply -f /tmp/manifests/app3/app3-service.yaml
kubectl apply -f /tmp/manifests/app3/app3-expose.yaml
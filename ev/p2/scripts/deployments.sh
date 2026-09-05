#!/bin/bash
set -eu
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "Waiting for k3s API to respond..."
until kubectl get nodes >/dev/null 2>&1; do
  echo "  ...not ready yet, retrying in 20s"
  sleep 20
done

echo "===> restarting k3s"
rc-service k3s restart
sleep 20


echo "Applying application manifests ..."
kubectl apply -f /vagrant/confs/.

echo "Listing Deployments:"
kubectl get deployments
echo "Listing Services:"
kubectl get services

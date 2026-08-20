#!/bin/bash

set -eu

echo "k3s installed ..."

echo "Waiting for the Kubernetes API server to wake up..."
until kubectl get nodes >/dev/null 2>&1; do
  sleep 2
done
echo "API server is up!"

echo "Applying application manifests ..."
kubectl apply -f /vagrant/confs/.

echo "Waiting for the Deployments"
kubectl wait --for=condition=Available deployment/app-one --timeout=60s
kubectl wait --for=condition=Available deployment/app-two --timeout=60s
kubectl wait --for=condition=Available deployment/app-three --timeout=60s

echo "The App deployements are Available ..."

echo "Listing Pods :"
kubectl get pods

echo "Listing Deployments :"
kubectl get deployments

echo "Listing Services :"
kubectl get services

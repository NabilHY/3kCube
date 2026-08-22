#!/bin/bash

set -eu

export KUBECONFIG=/etc/rancher/k3s/config.yaml

echo "k3s installed ..."

echo "Waiting for the Kubernetes API server to start..."
until kubectl get nodes >/dev/null 2>&1; do
	sleep 10
	echo "10 secs ..."
done
echo "API server is up!"

echo "Applying application manifests ..."
kubectl apply -f /vagrant/confs/.

echo "Wait for Traefik CRds to be fully registered by the system"
kubectl wait --for=condition=established --timeout=60s crd/ingressroutes.traefik.containo.us

echo "Waiting for the Deployments"
kubectl wait --for=condition=Available deployment/app-one --timeout=120s
kubectl wait --for=condition=Available deployment/app-two --timeout=120s
kubectl wait --for=condition=Available deployment/app-three --timeout=120s

echo "The App deployements are Available ..."

echo "Listing Pods :"
kubectl get pods

echo "Listing Deployments :"
kubectl get deployments

echo "Listing Services :"
kubectl get services

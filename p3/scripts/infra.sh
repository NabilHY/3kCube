#!/bin/bash

set -eou pipefail

echo "===> Delete the k3d cluster (nodes, services, pods, network)"
k3d cluster delete cd-cluster || true

echo "===> Complete Docker System prune"
docker system prune -af --volumes

echo "INFRA Build :==> [1/6] spinning k3d cluster 'cd-cluster' with port mapping ..."
k3d cluster create cd-cluster -p "8000:8885@loadbalancer"

echo "Sleeping for 10 seconds to let cluster stabilize ..."
sleep 10

echo "==> Verifying cluster connection with kubectl ..."
kubectl get nodes

echo "===> Apply Namespaces Bootstrap manifests ..."
kubectl apply -f confs/namespaces.yml

echo "Deploy ArgoCD :===> [2/6] Apply ArgoCD installation manifests ..."
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "===> Setting ArgoCD reconcile timeout to 10 seconds for fast dev sync ..."
kubectl patch cm argocd-cm -n argocd --type merge -p '{"data": {"timeout.reconcile": "10s"}}'

echo "===> Waiting for ArgoCD server pod to reach Ready state ..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

echo "===> Extract auto-generated initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo "" # Line break for clean terminal formatting

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"

echo "===> [5/6] Applying ArgoCD Application manifest ..."
kubectl apply -f "$CONFS_DIR/application.yml"

echo "===> [6/6] Port-forward the API server (Access via https://localhost:4000)"
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 4000:443

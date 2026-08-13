#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"
BOOTSTRAP_DIR="$CONFS_DIR/bootstrap"
APP_DIR="$CONFS_DIR/app"

echo "===> Delete the k3d cluster (nodes, services, pods, network)"
k3d cluster delete cd-cluster || true

echo "INFRA Build :==> [1/6] spinning k3d cluster 'cd-cluster' with port mapping ..."
# k3d lb receive http ingress traffic on port 80 --- k3d -> internal ingress 80
k3d cluster create cd-cluster -p "8000:80@loadbalancer"

echo "Sleeping for 10 seconds to let cluster stabilize ..."
sleep 10

echo "==> Verifying cluster connection with kubectl ..."
kubectl get nodes

echo "===> Apply Namespaces Bootstrap manifests ..."
kubectl apply -f "$BOOTSTRAP_DIR/namespaces.yml"

# point in time where gitea shall be up and running and has started tracking the app directory
echo "===> Installing gitea"
bash "$SCRIPT_DIR/git.sh"

#echo "Deploy ArgoCD :===> [2/6] Apply ArgoCD installation manifests ..."
#kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#
#echo "===> Setting ArgoCD reconcile timeout to 10 seconds, through argocd-cm ..."
#kubectl apply -f "$BOOTSTRAP_DIR/argocd-cm.yml"
#
#echo "===> Waiting for ArgoCD server pod to reach Ready state ..."
#kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
#
#echo "===> Extract auto-generated initial admin password:"
#kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
#echo "" # Line break for clean terminal formatting
#
#echo "===> [5/6] Applying ArgoCD Application manifest ..."
#kubectl apply -f "$BOOTSTRAP_DIR/application.yml"
#
#echo "===> [6/6] Applying ArgoCD Ingress for web UI access ..."
#kubectl apply -f "$BOOTSTRAP_DIR/argocd-ingress.yml"

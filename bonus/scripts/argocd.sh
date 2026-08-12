#!/bin/bash

set -eou pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFS_DIR="$ROOT_DIR/confs"

echo "===> Applying ArgoCD LoadBalancer service..."
kubectl apply -f "$CONFS_DIR/argocd-service.yml"

echo "===> Applying ArgoCD Ingress..."
kubectl apply -f "$CONFS_DIR/argocd-ingress.yml"

echo "===> Applying ArgoCD Application manifest..."
kubectl apply -f "$CONFS_DIR/application.yml"

echo "===> ArgoCD is ready at http://localhost:4000"


#!/bin/bash

set -eou pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFS_DIR="$ROOT_DIR/confs"

echo "===> [*] Applying ArgoCD Application manifest ..."
kubectl apply -f "$CONFS_DIR/application.yml"

echo "===> [*] Port-forward the API server (Access via https://localhost:4000)"
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 4000:443

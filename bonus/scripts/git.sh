#!/bin/bash

set -eou pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/confs/bootstrap"

NAMESPACE="gitea"
REALESE_NAME="my-gitea"

echo "[**] Installing Helm..."
if ! command -v helm &>/dev/null; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
  chmod 700 /tmp/get_helm.sh /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
else
  echo "HELM already installed .."
fi

echo "[**] Adding Gitea Helm repository..."
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update

echo "[**] Applying Gitea Ingress for web UI access ..."
kubectl apply -f "$BOOTSTRAP_DIR/gitea-ingress.yml"

echo "[**] Deploying Gitea Chart with custom values"
helm upgrade --install my-gitea gitea-charts/gitea \
  -n gitea \
  -f "$BOOTSTRAP_DIR/gitea-values.yml"

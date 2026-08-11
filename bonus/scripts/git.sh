#!/bin/bash

set -eou pipefail

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
CONFS_DIR="$ROOT_DIR/confs"

echo "$ROOT_DIR/confs"

NAMESPACE="gitea"
REALESE_NAME="my-gitea"
echo "[**] Ensuring namespace ${NAMESPACE} exists"
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
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

echo "[**] Deploying Gitea Chart with custom values"
helm upgrade --install my-gitea gitea-charts/gitea \
  -n gitea \
  -f "$CONFS_DIR/gitea-values.yaml"

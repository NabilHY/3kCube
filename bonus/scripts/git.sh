#!/bin/bash

set -eou pipefail

#echo "[**] Creating a namespace for gitea"
#kubectl create namespace gitea || true
#
#echo "[**] Installing HELM"
#
#echo "[**] Installing HELM through script"
#curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
#chmod 700 /tmp/get_helm.sh
#/tmp/get_helm.sh
#
#echo "[**] Installing Gitea"
#helm repo add gitea-charts https://dl.gitea.com/charts/
#helm repo update
#
#echo "[**] Deploying Chart"
#helm install my-gitea gitea-charts/gitea --create-namespace -n gitea

CONFS_DIR="$(dirname "$0")/confs"
NAMESPACE="gitea"
REALESE_NAME="my-gitea"

echo "[**] Ensuring namespace ${NAMESPACE} exists"
#? :
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

echo "[**] Installing/Updating Helm..."
if ! command -v helm &>/dev/null; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/main/scripts/get-helm-3
  chmod 700 /tmp/get_helm.sh
  /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
fi

echo "[**] Adding Gitea Helm repository..."
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update

echo "[**] Deploying Gitea Chart with custom values"
helm upgrade --install my-gitea gitea-charts/gitea \
  -n gitea \
  -f "$CONFS_DIR/gitea-values.yaml"

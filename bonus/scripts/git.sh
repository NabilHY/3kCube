#!/bin/bash

set -eou pipefail

GITEA_URL="http://gitea.localhost:8000"

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/confs/bootstrap"

NAMESPACE="gitea"
REALESE_NAME="my-gitea"

MANIFESTS_DIR="$ROOT_DIR/confs/app/"

echo "[**] Adding Gitea Helm repository..."
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update

echo "[**] Applying Gitea Ingress for web UI access ..."
kubectl apply -f "$BOOTSTRAP_DIR/gitea-ingress.yml"

echo "[**] Deploying Gitea Chart with custom values"
helm upgrade --install my-gitea gitea-charts/gitea \
  -n gitea \
  -f "$BOOTSTRAP_DIR/gitea-values.yml"

echo "[**] waiting for Gitea pod to be ready ...  "
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gitea -n "$NAMESPACE" --timeout=300s

echo "[**] Waiting for Gitea Http API to be reachable at gite.localhost:8000"
until [ "$(curl -s -o /dev/null -w "%{http_code}" "$GITEA_URL")" -eq 200 ]; do
  echo "waiting on gitea url to be reachable ..."
  sleep 2
done

echo "[**] Creating the iot repo on gitea server (skipping if it already exists)"
REPO_HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u 'root:giteaPassword123!' \
  -H 'Content-Type: application/json' \
  -X POST 'http://gitea.localhost:8000/api/v1/user/repos' \
  -d '{"name":"iot-gitops","private":false,"auto_init":false}')
if [ "$REPO_HTTP_CODE" -eq 201 ]; then
  echo "Repository created successfully."
elif [ "$REPO_HTTP_CODE" -eq 409 ]; then
  echo "Repository already exists, continuing..."
else
  echo "Error: unexpected HTTP $REPO_HTTP_CODE when creating repo" >&2
  exit 1
fi

GITEA_URL='http://root:giteaPassword123!@gitea.localhost:8000/root/iot-gitops.git'

echo "[**] Initializing git repository in $MANIFESTS_DIR"
if [ -d "$MANIFESTS_DIR/.git" ]; then
  echo "Git repository already initialized, skipping git init."
else
  git init --initial-branch=main "$MANIFESTS_DIR"
  git -C "$MANIFESTS_DIR" config user.name "iot-bootstrap"
  git -C "$MANIFESTS_DIR" config user.email "iot-bootstrap@local"
fi

echo "[**] Staging and committing manifests"
git -C "$MANIFESTS_DIR" add -A
if git -C "$MANIFESTS_DIR" diff --cached --quiet; then
  echo "No changes to commit, skipping."
else
  git -C "$MANIFESTS_DIR" commit -m "Initial commit: app manifests"
fi

echo "[**] Adding Gitea as remote origin"
if git -C "$MANIFESTS_DIR" remote get-url origin &>/dev/null; then
  echo "Remote 'origin' already exists, updating URL."
  git -C "$MANIFESTS_DIR" remote set-url origin "$GITEA_URL"
else
  git -C "$MANIFESTS_DIR" remote add origin "$GITEA_URL"
fi

echo "[**] Pushing to Gitea repository (main branch)"
git -C "$MANIFESTS_DIR" push -u origin main

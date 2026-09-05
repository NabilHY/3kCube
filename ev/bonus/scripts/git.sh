# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    git.sh                                             :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nhayoun <nhayoun@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 19:20:48 by nhayoun           #+#    #+#              #
#    Updated: 2026/08/26 19:20:49 by nhayoun          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

set -eou pipefail

GITEA_URL="http://gitea.localhost:8000"

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/confs/bootstrap"

NAMESPACE="gitea"
MANIFESTS_DIR="$ROOT_DIR/confs/app/"
SECRET_FILE="$BOOTSTRAP_DIR/gitea-admin.enc.yml"

echo "[**] Adding Gitea Helm repository..."
helm repo add gitea-charts https://dl.gitea.com/charts/
helm repo update

if ! command -v git >/dev/null 2>&1; then
	sudo dnf install git -y
fi

mkdir -p ~/.config/sops/age

cat << EOF > ~/.config/sops/age/keys.txt
# created: 2026-08-17T09:01:12-04:00
# public key: age1efdgz5laght76ntu0nuszvfl3jld5en7zcvgvp32gs43v4k9qugsuhhywr
AGE-SECRET-KEY-1NQV5V80P04RX0J0JX067CHT85MSEJSSFPE8SRC3P6YMEEU73J6UQGZ48GF
EOF

chmod 600 ~/.config/sops/age/keys.txt

if ! command -v age >/dev/null 2>&1; then
  echo "Installing age ..."
  sudo dnf install age -y
fi

if ! command -v sops >/dev/null 2>&1; then
  echo "Installing SOPS ..."
  curl -LO https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.amd64
  sudo mv sops-v3.13.3.linux.amd64 /usr/local/bin/sops
  sudo chmod +x /usr/local/bin/sops
fi

DECRYPTED_SECRET="$(sops --decrypt "$SECRET_FILE")"
echo "$DECRYPTED_SECRET" | kubectl apply -f -

if ! command -v yq >/dev/null 2>&1; then
  echo "installing yq..."
  sudo dnf install yq -y
fi

GITEA_ADMIN_USER="$(echo "$DECRYPTED_SECRET" | yq '.stringData.username')"
GITEA_ADMIN_PASSWORD="$(echo "$DECRYPTED_SECRET" | yq '.stringData.password')"
unset DECRYPTED_SECRET

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
  -u "${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}" \
  -H 'Content-Type: application/json' \
  -X POST "${GITEA_URL}/api/v1/user/repos" \
  -d '{"name":"iot-gitops","private":false,"auto_init":false}')
if [ "$REPO_HTTP_CODE" -eq 201 ]; then
  echo "Repository created successfully."
elif [ "$REPO_HTTP_CODE" -eq 409 ]; then
  echo "Repository already exists, continuing..."
else
  echo "Error: unexpected HTTP $REPO_HTTP_CODE when creating repo" >&2
  exit 1
fi

GIT_REMOTE_URL="http://${GITEA_ADMIN_USER}:${GITEA_ADMIN_PASSWORD}@gitea.localhost:8000/${GITEA_ADMIN_USER}/iot-gitops.git"

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
  git -C "$MANIFESTS_DIR" remote set-url origin "$GIT_REMOTE_URL"
else
  git -C "$MANIFESTS_DIR" remote add origin "$GIT_REMOTE_URL"
fi

echo "[**] Pushing to Gitea repository (main branch)"
git -C "$MANIFESTS_DIR" push -u origin main

unset GITEA_ADMIN_PASSWORD

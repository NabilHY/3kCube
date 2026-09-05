# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    infra.sh                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nhayoun <nhayoun@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 19:20:53 by nhayoun           #+#    #+#              #
#    Updated: 2026/08/26 19:20:54 by nhayoun          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFS_DIR="$SCRIPT_DIR/../confs"
BOOTSTRAP_DIR="$CONFS_DIR/bootstrap"
APP_DIR="$CONFS_DIR/app"

echo "===> Delete the k3d cluster (nodes, services, pods, network)"
k3d cluster delete cd-cluster || true

echo "INFRA Build :==> [*] spinning k3d cluster 'cd-cluster' with port mapping ..."
# k3d lb receive http ingress traffic on port 80 --- k3d -> internal ingress 80
k3d cluster create cd-cluster -p "8000:80@loadbalancer"

MAX_ATTEMPTS=3
for attempt in $(seq 1 $MAX_ATTEMPTS); do
  echo "===> Cluster bring-up attempt $attempt/$MAX_ATTEMPTS"
  k3d cluster delete cd-cluster || true
  k3d cluster create cd-cluster -p "8000:80@loadbalancer"

  if kubectl wait --for=condition=Ready nodes --all --timeout=120s \
     && kubectl rollout status deployment/coredns -n kube-system --timeout=180s \
     && kubectl wait --for=condition=complete job/helm-install-traefik-crd -n kube-system --timeout=180s \
     && kubectl wait --for=condition=complete job/helm-install-traefik -n kube-system --timeout=180s \
     && kubectl rollout status deployment/traefik -n kube-system --timeout=180s; then
    echo "===> Cluster up on attempt $attempt"
    break
  fi

  if [ "$attempt" -eq "$MAX_ATTEMPTS" ]; then
    echo "===> Cluster failed to come up after $MAX_ATTEMPTS attempts"
    exit 1
  fi
  echo "===> Attempt $attempt failed, retrying..."
  sleep 20
done

echo "==> Verifying cluster connection with kubectl ..."
kubectl get nodes

echo "===> Apply Namespaces Bootstrap manifests ..."
kubectl apply -f "$BOOTSTRAP_DIR/namespaces.yml"

# point in time where gitea shall be up and running and has started tracking the app directory
echo "===> Installing gitea"
bash "$SCRIPT_DIR/git.sh"

echo "Deploy ArgoCD :===> [*] Apply ArgoCD installation manifests ..."
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "===> Setting ArgoCD reconcile timeout to 10 seconds, through argocd-cm ..."
kubectl apply -f "$BOOTSTRAP_DIR/argocd-cm.yml"

echo "===> Restarting ArgoCD in case server doesnt read the argocd-cm"
kubectl rollout restart deployment/argocd-server -n argocd

echo "===> Waiting for ArgoCD server pod to reach Ready state ..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

echo "===> Extract auto-generated initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo "" # Line break for clean terminal formatting

echo "===> [*] Applying ArgoCD Application manifest ..."
kubectl apply -f "$BOOTSTRAP_DIR/application.yml"

echo "===> [*] Applying ArgoCD Ingress for web UI access ..."
kubectl apply -f "$BOOTSTRAP_DIR/argocd-ingress.yml"

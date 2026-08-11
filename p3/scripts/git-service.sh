#!/bin/bash

echo " +++ Installing Gitea using HELM +++ "

set -eou pipefail

echo "Installing Helm ..."
curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 /tmp/get_helm.sh
/tmp/get_helm.sh

echo "Running a Non-customized install of Gitea ..."
helm repo add gitea-charts https://dl.gitea.com/charts/

helm install gitea gitea-charts/gitea

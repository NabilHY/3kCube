#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo " +++ Installing container environment +++ "
bash "$SCRIPT_DIR/container-env.sh"

echo " +++ Setting up infrastructure +++ "
sg docker -c "$SCRIPT_DIR/infra.sh"

echo " +++ Settings up GitRepo +++ "
bash "$SCRIPT_DIR/git.sh"

echo " +++ Deploying ArgoCD +++ "
bash "$SCRIPT_DIR/argocd.sh"

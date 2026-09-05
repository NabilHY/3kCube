# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    container-env.sh                                   :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nhayoun <nhayoun@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 19:20:37 by nhayoun           #+#    #+#              #
#    Updated: 2026/08/26 19:20:38 by nhayoun          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

set -eou pipefail

# --- Error Handling Trap ---
trap 'echo -e "\nError: Command failed on line $LINENO: $BASH_COMMAND" >&2' ERR

echo "==> [1/6] Installing Docker Engine ..."
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo --overwrite
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> [2/6] Starting the docker engine ..."
sudo systemctl enable --now docker

echo "==> [3/6] Configuring Docker permissions ..."
sudo groupadd -f docker
sudo usermod -aG docker "$USER"

echo "===> "
sudo docker pull rancher/mirrored-pause:3.6

echo "==> [4/6] Installing k3d ..."
if ! command -v k3d &>/dev/null; then
  wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  echo "k3d is already installed. Skipping download."
fi

echo "==> [5/6] Installing kubectl ..."
if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl # Clean up downloaded binary
else
  echo "kubectl is already installed. Skipping download."
fi

echo "[6/6] Installing Helm..."
if ! command -v helm &>/dev/null; then
  curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
  chmod 700 /tmp/get_helm.sh /tmp/get_helm.sh
  /tmp/get_helm.sh
  rm -f /tmp/get_helm.sh
else
  echo "HELM already installed .."
fi

# Verify docker works via 'sg'
sg docker -c "docker ps"

#!/bin/bash

set -eou pipefail

# --- Error Handling Trap ---
trap 'echo -e "\nError: Command failed on line $LINENO: $BASH_COMMAND" >&2' ERR

echo "==> [1/5] Installing Docker Engine ..."
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo --overwrite
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> [2/5] Starting the docker engine ..."
sudo systemctl enable --now docker

echo "==> [3/5] Configuring Docker permissions ..."
sudo groupadd -f docker
sudo usermod -aG docker "$USER"

echo "==> [4/5] Installing k3d ..."
if ! command -v k3d &>/dev/null; then
  wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  echo "k3d is already installed. Skipping download."
fi

echo "==> [5/5] Installing kubectl ..."
if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl # Clean up downloaded binary
else
  echo "kubectl is already installed. Skipping download."
fi

# Verify docker works via 'sg'
sg docker -c "docker ps"

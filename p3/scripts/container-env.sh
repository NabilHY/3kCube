#!/bin/bash

set -eou pipefail

# --- Error Handling Trap ---
trap 'echo -e "\nError: Command failed on line $LINENO: $BASH_COMMAND" >&2' ERR

if [[ "${1:-}" == "--post-docker" ]]; then
  echo "==> [4/6] Installing k3d ..."
  if ! command -v k3d &>/dev/null; then
    wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
  else
    echo "k3d is already installed. Skipping download."
  fi

  echo "==> [5/6] Managing k3d cluster 'mycluster' ..."
  if k3d cluster list | grep -q "^mycluster"; then
    echo "Cluster 'mycluster' already exists. Skipping creation."
  else
    k3d cluster create mycluster
  fi
  echo "==> [6/6] Installing/Updating kubectl ..."
  # Download and install only if kubectl isn't present or update is desired
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
  rm -f kubectl # Clean up downloaded binary

  echo "Sleeping for 10 seconds to let cluster stabilize ..."
  sleep 10

  echo "==> Verifying cluster connection with kubectl ..."
  kubectl get nodes

  echo "✅ All steps completed successfully!"
fi

echo "==> [1/6] Installing Docker Engine ..."
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo --overwrite
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "==> [2/6] Starting the docker engine ..."
sudo systemctl enable --now docker

echo "==> [3/6] Configuring Docker permissions ..."
sudo groupadd -f docker
sudo usermod -aG docker "$USER"

# Verify docker works via 'sg'
sg docker -c "docker ps"

echo "==> Re-executing script with active 'docker group context...'"
exec sg docker -c "bash \"$0\" --post-docker"

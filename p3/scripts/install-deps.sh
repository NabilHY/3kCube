#!/bin/bash

set -eou pipefail

echo "Installing Docker Engine ..."
# set up docker repository
sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo --overwrite
# install docker packages
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

echo "Starting the docker engine ..."
sudo systemctl enable --now docker || true

# create docker group
sudo groupadd -f docker || true
# add user to docker group
sudo usermod -aG docker $USER || true
#verify docker works without sudo
sg docker -c "docker ps"

echo "Installing k3d ..."

wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

if k3d cluster list | grep -q "^mycluster\s"; then
  echo "Cluster 'mycluster' already exists. Skipping creation."
else
  echo "Creating cluster 'mycluster'..."
  k3d cluster create mycluster
fi

echo "sleeping for 10 seconds ..."
sleep 10

echo "Downloading kubectl latest release"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

echo "Installing kubectl ..."
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "use new cluster with kubectl"
kubectl get nodes

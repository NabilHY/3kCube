#!/bin/sh
set -e

SERVER_IP="$1"
TOKEN_FILE="$2"

echo "=========> Installing K3s Server <========="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${SERVER_IP} --flannel-iface=eth1 --disable=traefik --disable=metrics-server" sh -

echo "=========> Waiting for K3s control plane to become ready <========="
until k3s kubectl get nodes > /dev/null 2>&1; do 
  sleep 2
done

# Setup kubeconfig for vagrant user (using kubectl without typing sudo every time)
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 600 /home/vagrant/.kube/config
echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> /etc/profile
 

echo "=========> K3s Server Ready <========="
k3s kubectl get nodes

echo "=========> Writing K3s Token <========="
TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
echo "$TOKEN" > "${TOKEN_FILE}"
chmod 600 "${TOKEN_FILE}"
echo "K3s token written to shared Vagrant folder."  
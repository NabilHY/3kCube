#!/bin/sh
set -e

SERVER_IP="$1"

echo "=========> Installing prerequisities <========="
apk update
apk add curl
rc-update add cgroups boot
service cgroups start

mkdir -p /sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup /sys/fs/cgroup/memory 2>/dev/null || true

echo "=========> Installing K3s Server <========="
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip=${SERVER_IP} --flannel-iface=eth1 " sh -

echo "=========> Waiting for K3s control plane to become ready <========="
until k3s kubectl get nodes > /dev/null 2>&1; do
  sleep 2
done

# Setup kubeconfig for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
chmod 600 /home/vagrant/.kube/config

echo 'export KUBECONFIG=/home/vagrant/.kube/config' >> /etc/profile
 
echo "=========> K3s Server Ready <========="
k3s kubectl get nodes

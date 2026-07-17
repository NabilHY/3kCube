#!/bin/bash
set -euo pipefail
dnf install nc -y
until nc -z 192.168.56.110 6443; do
  sleep 2
done
export INSTALL_K3S_EXEC="agent --node-name=member2sw --node-ip=192.168.56.111 --flannel-iface=eth1"
export K3S_TOKEN=$(sudo cat /vagrant/node-token | tr -d '[:space:]')
echo "tokeeeeen $K3S_TOKEN"
export K3S_URL="https://192.168.56.110:6443"
if [ -z "$K3S_TOKEN" ]; then
  echo "Error: node-token file is empty!" >&2
  exit 1
fi
echo "Starting K3s installation..."
curl -sfL http://get.k3s.io | sh -
echo "K3s installation succeeded!"

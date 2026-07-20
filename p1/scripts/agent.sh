#!/bin/bash
set -euo pipefail

# Same reasoning as server.sh — wipe any state left over from a previous
# join attempt before this one. This specifically prevents an agent from
# holding credentials cached against a CA the server no longer has.
systemctl stop k3s-agent 2>/dev/null || true
rm -rf /var/lib/rancher/k3s /etc/rancher/k3s

dnf install -y nc
until nc -z 192.168.56.110 6443; do
  echo "Waiting for server API to be reachable..."
  sleep 2
done

echo "Waiting for server token..."
timeout=300
elapsed=0
until [ -s /vagrant/node-token ]; do
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "Timed out waiting for node-token" >&2
    exit 1
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

K3S_TOKEN=$(cat /vagrant/node-token | tr -d '[:space:]')
if [ -z "$K3S_TOKEN" ]; then
  echo "Error: node-token file is empty!" >&2
  exit 1
fi
export K3S_TOKEN
export K3S_URL="https://192.168.56.110:6443"
export INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1"

echo "Starting K3s agent installation..."
curl -sfL https://get.k3s.io | sh -
echo "K3s installation succeeded!"

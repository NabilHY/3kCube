#!/bin/sh
set -eu

apk add --no-cache netcat-openbsd

until nc -z 192.168.56.110 6443; do
  echo "Waiting for server API to be reachable..."
  sleep 2
done

# Read the pre-generated cluster token injected by the Makefile
NODE_TOKEN=$(cat /vagrant/.node-token | tr -d '[:space:]')
if [ -z "$NODE_TOKEN" ]; then
  echo "Error: /vagrant/.node-token is missing or empty!" >&2
  exit 1
fi

# create default config dir and define node settings prior to bin installation
mkdir -p /etc/rancher/k3s

cat >/etc/rancher/k3s/config.yaml <<EOF
token: "${NODE_TOKEN}"
kubelet-arg:
  - "max-pods=110"
  - "resolv-conf=/etc/resolv.conf"
EOF

export K3S_TOKEN=$NODE_TOKEN
export K3S_URL="https://192.168.56.110:6443"
export INSTALL_K3S_EXEC="--node-ip=192.168.56.111 --flannel-iface=eth1"
echo "Starting K3s agent installation..."
curl -sfL https://get.k3s.io | sh -
echo "K3s installation succeeded!"

echo "Waiting for k3s-agent service to be active..."
until rc-service k3s-agent status 2>/dev/null | grep -q "started"; do
  sleep 2
done
echo "K3s agent service is running."

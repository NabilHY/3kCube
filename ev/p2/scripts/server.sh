#!/bin/sh
set -eu

# create default config dir and define node settings prior to bin installation
mkdir -p /etc/rancher/k3s

cat >/etc/rancher/k3s/config.yaml <<EOF
kubelet-arg:
  - "max-pods=110"
  - "resolv-conf=/etc/resolv.conf"
EOF

# Execute installer script
export K3S_NODE_NAME="$SERVER_HOST"
export INSTALL_K3S_EXEC="--node-ip=$SERVER_IP --advertise-address=$SERVER_IP --flannel-iface=eth1 --write-kubeconfig-mode 644 --disable coredns "
echo "Starting K3s server installation..."
curl -sfL https://get.k3s.io | sh -
echo "K3s installation succeeded!"

# Set up vagrant user shell environment
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >>/home/vagrant/.bashrc

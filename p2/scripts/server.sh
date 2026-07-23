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
export INSTALL_K3S_EXEC="--node-ip=192.168.56.110 --advertise-address=192.168.56.110 --flannel-iface=eth1 --write-kubeconfig-mode 644"
echo "Starting K3s server installation..."
curl -sfL https://get.k3s.io | sh -
echo "K3s installation succeeded!"

# Set up vagrant user shell environment
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >>/home/vagrant/.bashrc

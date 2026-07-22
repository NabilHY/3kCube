#!/bin/bash

set -euo pipefail

sed -i '/--disable/d' /etc/systemd/system/k3s.service

sudo systemctl daemon-reload
sudo systemctl restart k3s

# Wait for k3s to be ready after restart
sleep 5

echo " --- Configuration ---"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
/usr/local/bin/kubectl get nodes -o wide

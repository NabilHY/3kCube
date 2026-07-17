#!/bin/bash
set -euo pipefail
apt get update -y
dnf install ca-certificates -y
# update the certificate authority trust store
#
dnf install -y container-selinux iptables
dnf install -y https://rpm.rancher.io/k3s/stable/common/centos/9/noarch/k3s-selinux-1.6-1.el9.noarch.rpm
echo "Dependencies installed on host: $(uname -n)"

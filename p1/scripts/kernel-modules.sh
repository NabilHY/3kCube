#!/bin/bash

set -eu

# 1. Persist kernel modules across reboots
cat >/etc/modules-load.d/k3s.conf <<EOF
br_netfilter
overlay
nf_conntrack
EOF

# 2. Load modules immediately
modprobe br_netfilter
modprobe overlay
modprobe nf_conntrack

# 3. Configure sysctl network settings
cat >>/etc/sysctl.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl parameters immediately
sysctl -p

# 4. Enable and start OpenRC cgroups management
rc-service cgroups start
rc-update add cgroups default

# Disable active swap
swapoff -a

# Remove swap entries from fstab to prevent re-activation on reboot
sed -i '/swap/d' /etc/fstab

# Verify swap is  0
free -h

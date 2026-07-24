#!/bin/sh
set -eu

# Update repositories and system binaries
apk update && apk upgrade

# Install required tools and K3s dependencies
apk add --no-cache \
  curl \
  bash \
  coreutils \
  findutils \
  util-linux \
  mount \
  blkid \
  nfs-utils \
  iptables \
  cni-plugins

# Set vagrant's login shell to bash (Alpine defaults to ash)
sed -i 's|vagrant:/bin/ash|vagrant:/bin/bash|' /etc/passwd

# Inject aliases into vagrant's environment
cp /vagrant/confs/aliases /home/vagrant/.bash_aliases
grep -q 'bash_aliases' /home/vagrant/.bashrc 2>/dev/null || echo '. ~/.bash_aliases' >> /home/vagrant/.bashrc

echo "deps installed"

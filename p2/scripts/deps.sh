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

#cp /vagrant/confs/aliases /home/vagrant/.bash_aliases
#cat ~/..bash_aliases >>.bashrc
#source ~/.bashrc
#echo '. ~/.bash_aliases' >>/home/vagrant/.bashrc

echo "deps installed"

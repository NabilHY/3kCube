#!/bin/bash

SSH_FILE="/etc/ssh/sshd_config"

set -eou pipefail

echo "Using sed to edit the sshd config file"
sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" "$SSH_FILE" 
sudo sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" "$SSH_FILE"

sudo systemctl restart sshd

echo "ssh settings restarted, public key auth is enabled"

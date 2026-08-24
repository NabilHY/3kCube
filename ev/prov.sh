#!/bin/bash

#set -eou pipefail

#sudo dnf update -y

echo "install git"
sudo dnf install -y git libevent-devel bison flex make cmake gettext tar automake gcc ncurses-devel libevent-devel ncurses-devel wget
echo "installing neovim"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

echo "setup lazyvim env ..."
git clone https://github.com/NabilHY/tmux-nvim-config.git

echo "installing tmux ..."
git clone https://github.com/tmux/tmux.git
cd tmux
sh autogen.sh
./configure
make && sudo make install

cd "$HOME"


echo "setup tmux config"
sudo ln -sf "$HOME/tmux-nvim-config/.tmux.conf" "$HOME/.tmux.conf"
sudo ln -sf "/opt/nvim-linux-x86_64/bin/nvim" "/usr/local/bin/nvim"

echo "setup nvim config"
mkdir -p "$HOME/.config/nvim"
cp -rf "$HOME/tmux-nvim-config/nvim/" "$HOME/.config/"

echo "VM Provisioned ..."

# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    agent.sh                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: aessaoud <aessaoud@student.1337.ma>        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 18:33:36 by aessaoud          #+#    #+#              #
#    Updated: 2026/08/26 18:33:57 by aessaoud         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/sh
set -e

SERVER_IP="$1"
AGENT_IP="$2"
TOKEN_FILE="$3"


echo "=========> Waiting for K3s server token <========="
until [ -f "${TOKEN_FILE}" ]; do
  echo "Waiting for server to generate token..."
  sleep 3
done

TOKEN=$(cat "${TOKEN_FILE}")
rm -f "$TOKEN_FILE"




echo "=========> Waiting for K3s server API <========="
until curl -k -s "https://${SERVER_IP}:6443" > /dev/null 2>&1; do
  echo "Waiting for K3s API at https://${SERVER_IP}:6443..."
  sleep 3
done

echo "=========> Installing K3s Agent <========="
curl -sfL https://get.k3s.io | \
  K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN="${TOKEN}" \
  INSTALL_K3S_EXEC="--node-ip=${AGENT_IP} --flannel-iface=eth1" \
  sh -



echo "=========> K3s Agent joined successfully <========="
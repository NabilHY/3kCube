# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    common.sh                                          :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: aessaoud <aessaoud@student.1337.ma>        +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 18:33:45 by aessaoud          #+#    #+#              #
#    Updated: 2026/08/26 18:33:56 by aessaoud         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/sh
set -e

echo "=========> Installing prerequisities <========="
apk update
apk add curl
rc-update add cgroups boot
service cgroups start


mkdir -p /sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup /sys/fs/cgroup/memory 2>/dev/null || true 
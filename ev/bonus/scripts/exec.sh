# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    exec.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nhayoun <nhayoun@student.42.fr>            +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 19:20:44 by nhayoun           #+#    #+#              #
#    Updated: 2026/08/26 19:54:23 by nhayoun          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo " +++ Installing container environment +++ "
bash "$SCRIPT_DIR/container-env.sh"

echo " +++ Setting up infrastructure +++"
sg docker -c "$SCRIPT_DIR/infra.sh"

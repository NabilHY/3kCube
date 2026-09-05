# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    exec.sh                                            :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: nhayoun <nhayoun@student.1337.ma>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/08/26 18:36:10 by nhayoun           #+#    #+#              #
#    Updated: 2026/08/26 18:36:24 by nhayoun          ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo " +++ Installing container environment +++ "
bash "$SCRIPT_DIR/container-env.sh"

echo " +++ Setting up infrastructure +++"
sg docker -c "$SCRIPT_DIR/infra.sh"

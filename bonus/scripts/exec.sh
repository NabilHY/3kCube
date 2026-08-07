#!/bin/bash

set -eou pipefail

SCRIPT_DIR="$(pwd)"

echo " +++ Installing container environment +++ "
bash "$SCRIPT_DIR/container-env.sh"

echo " +++ Setting up infrastructure +++"
bash "$SCRIPT_DIR/infra.sh"

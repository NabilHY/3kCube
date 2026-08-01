#!/bin/bash

set -eou pipefail

echo " +++ Installing container environment +++"
bash "container-env.sh"

bash container-env.sh --post-docker w

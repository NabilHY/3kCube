#!/bin/bash

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y

apt-get install -y ca-certificates curl

# No SELinux on Debian — the k3s-selinux RPM is not needed.

echo "deps installed"

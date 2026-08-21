#!/bin/sh
set -e

echo "=========> Installing prerequisities <========="
apk update
apk add curl
rc-update add cgroups boot
service cgroups start


mkdir -p /sys/fs/cgroup/memory
mount -t cgroup -o memory cgroup /sys/fs/cgroup/memory 2>/dev/null || true 
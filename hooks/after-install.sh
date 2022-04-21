#!/usr/bin/env bash
set -euo pipefail

NIX_BUILD_GROUP_ID="30000"
NIX_BUILD_GROUP_NAME="nixbld"

# Setup group
groupadd -g "$NIX_BUILD_GROUP_ID" --system "$NIX_BUILD_GROUP_NAME"

# Add build users (same as number of cores on the machine to scale with `max-jobs = auto`)
cores=$(nproc)
for i in $(seq 1 $(($cores>32 ? $cores : 32))); do
    username="nixbld$i"
    uid=$((30000 + i))
    useradd \
      --home-dir /var/empty \
      --comment "Nix build user $i" \
      --gid "$NIX_BUILD_GROUP_ID" \
      --groups "$NIX_BUILD_GROUP_NAME" \
      --no-user-group \
      --system \
      --shell /sbin/nologin \
      --uid "$uid" \
      --password "!" \
      "$username"
done

if test -e /sys/fs/selinux; then
    semodule -i "/usr/share/selinux/packages/nix.pp"
fi

systemctl enable nix-daemon

systemctl start nix-daemon || true

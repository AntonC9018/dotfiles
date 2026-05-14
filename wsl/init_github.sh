#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.ssh
touch ~/.ssh/known_hosts
chmod 600 ~/.ssh/known_hosts

if ! ssh-keygen -F github.com >/dev/null; then
    ssh-keyscan github.com >> ~/.ssh/known_hosts
fi

exit 0

#!/usr/bin/env bash
set -euo pipefail

# Remove old github.com entries to avoid "Host key verification failed" errors
ssh-keygen -R github.com 2>/dev/null
# Scan and add the current GitHub keys to known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

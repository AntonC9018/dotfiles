#!/usr/bin/env bash

set -euo pipefail

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    target_user="$SUDO_USER"
else
    target_user="$(id -un)"
fi

if [[ "$target_user" == "root" ]]; then
    echo "Run this script while logged in as the non-root user to configure." >&2
    exit 1
fi

apt_path="$(command -v apt)"
apt_get_path="$(command -v apt-get)"
npm_path="$(command -v npm)"
visudo_path="$(command -v visudo)"
sudoers_file="/etc/sudoers.d/${target_user}-apt"
sudoers_rule="${target_user} ALL=(root) NOPASSWD: ${apt_path}, ${apt_get_path}, ${npm_path} install -g @openai/codex@latest"

temporary_rule="$(mktemp)"
trap 'rm -f "$temporary_rule"' EXIT
printf '%s\n' "$sudoers_rule" > "$temporary_rule"

"$visudo_path" -cf "$temporary_rule"
sudo install -o root -g root -m 0440 "$temporary_rule" "$sudoers_file"
sudo "$visudo_path" -cf "$sudoers_file"

echo "Enabled passwordless sudo for apt, apt-get, and the Codex npm install for ${target_user}."

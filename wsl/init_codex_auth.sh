#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.codex

WIN_USER="$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
SRC="/mnt/c/Users/${WIN_USER}/.codex/auth.json"
DST="$HOME/.codex/auth.json"

if [[ ! -f "$SRC" ]]; then
    echo "Source file not found: $SRC" >&2
    exit 1
fi

cp "$SRC" "$DST"
chmod 600 "$DST"

echo "Copied $SRC -> $DST"

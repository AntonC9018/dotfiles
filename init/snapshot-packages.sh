#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/default_packages_path_config.sh"
OUTPUT="${1:-$SNAPSHOT_PATH}"

if [ -f "$OUTPUT" ]; then
  read -rp "Snapshot '${OUTPUT}' already exists. Overwrite? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

dpkg --get-selections | awk '$2=="install" {print $1}' | sort > "$OUTPUT"

echo "Saved $(wc -l < "$OUTPUT") packages to ${OUTPUT}"
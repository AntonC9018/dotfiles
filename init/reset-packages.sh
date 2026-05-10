#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/default_packages_path_config.sh"
SNAPSHOT="${1:-$SNAPSHOT_PATH}"

if [ ! -f "$SNAPSHOT" ]; then
  echo "Error: snapshot file '${SNAPSHOT}' not found."
  echo "Run snapshot.sh first to create a baseline."
  exit 1
fi

echo "Using snapshot: ${SNAPSHOT} ($(wc -l < "$SNAPSHOT") packages)"

dpkg --get-selections | awk '$2=="install" {print $1}' | sort > /tmp/installed-pkgs.txt

TO_REMOVE=$(comm -23 /tmp/installed-pkgs.txt "$SNAPSHOT" | tr '\n' ' ')

if [ -z "$TO_REMOVE" ]; then
  echo "Nothing to remove — system matches snapshot."
else
  echo ""
  echo "Packages to remove:"
  comm -23 /tmp/installed-pkgs.txt "$SNAPSHOT"
  echo ""
  read -rp "Proceed with removal? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    sudo apt-get purge --autoremove -y $TO_REMOVE
  else
    echo "Aborted."
  fi
fi
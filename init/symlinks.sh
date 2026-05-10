#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

MAPPINGS_FILE="$REPO_ROOT/mappings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required"
    exit 1
fi

expand_path() {
    local path="$1"

    if [[ "$path" == "~/"* ]]; then
        echo "${HOME}/${path#"~/"}"
    else
        echo "$path"
    fi
}

confirm() {
    local prompt="$1"
    read -r -p "$prompt [y/N]: " reply
    [[ "$reply" == "y" || "$reply" == "Y" ]]
}

jq -r 'to_entries[] | @base64' "$MAPPINGS_FILE" | while read -r entry; do
    _jq() {
        echo "$entry" | base64 -d | jq -r "$1"
    }

    source_rel="$(_jq '.key')"
    target_raw="$(_jq '.value')"

    source_path="$REPO_ROOT/$source_rel"
    target_path="$(expand_path "$target_raw")"

    echo "Linking:"
    echo "  $target_path -> $source_path"

    mkdir -p "$(dirname "$target_path")"

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        echo "Warning: target already exists: $target_path"

        if [[ -L "$target_path" ]]; then
            echo "It is a symlink pointing to: $(readlink "$target_path")"
        fi

        if ! confirm "Replace it?"; then
            echo "Skipped."
            continue
        fi

        rm -rf "$target_path"
    fi

    ln -s "$source_path" "$target_path"
done

echo
echo "Done."
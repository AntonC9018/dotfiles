#!/usr/bin/env bash
set -euo pipefail
#TODO sudo, but write to user home, not sudo home?

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

copy_changed_directory() {
    local source_dir="$1"
    local target_dir="$2"
    local source_entry relative_path target_entry

    mkdir -p "$target_dir"

    while IFS= read -r -d '' source_entry; do
        relative_path="${source_entry#"$source_dir"/}"
        target_entry="$target_dir/$relative_path"

        if [[ -d "$source_entry" && ! -L "$source_entry" ]]; then
            if [[ -e "$target_entry" || -L "$target_entry" ]] && { [[ ! -d "$target_entry" ]] || [[ -L "$target_entry" ]]; }; then
                echo "Warning: target already exists and is not a directory: $target_entry"
                if ! confirm "Replace it?"; then
                    echo "Skipped."
                    continue
                fi
                rm -rf "$target_entry"
            fi
            mkdir -p "$target_entry"
            continue
        fi

        mkdir -p "$(dirname "$target_entry")"

        if [[ -L "$source_entry" ]]; then
            if [[ -L "$target_entry" && "$(readlink "$source_entry")" == "$(readlink "$target_entry")" ]]; then
                continue
            fi
        elif [[ -f "$source_entry" && -f "$target_entry" && ! -L "$target_entry" ]] && cmp -s "$source_entry" "$target_entry"; then
            continue
        elif [[ -d "$target_entry" && ! -L "$target_entry" ]]; then
            echo "Warning: target is a directory but source is a file: $target_entry"
            if ! confirm "Replace it?"; then
                echo "Skipped."
                continue
            fi
            rm -rf "$target_entry"
        elif [[ -e "$target_entry" || -L "$target_entry" ]]; then
            echo "Warning: target already exists: $target_entry"
            if [[ -L "$target_entry" ]]; then
                echo "It is a symlink pointing to: $(readlink "$target_entry")"
            fi
            if ! confirm "Replace it?"; then
                echo "Skipped."
                continue
            fi
            rm -rf "$target_entry"
        fi

        cp -a "$source_entry" "$target_entry"
    done < <(find "$source_dir" -mindepth 1 -print0)
}

jq -r 'to_entries[] | @base64' "$MAPPINGS_FILE" | while read -r entry; do
    _jq() {
        echo "$entry" | base64 -d | jq -r "$1"
    }

    source_rel="$(_jq '.key')"
    target_raw="$(_jq 'if (.value | type) == "object" then .value.target else .value end')"
    mode="$(_jq 'if (.value | type) == "object" then (.value.mode // "link") else "link" end')"

    if [[ "$mode" != "link" && "$mode" != "copy" ]]; then
        echo "Unsupported mapping mode '$mode' for $source_rel" >&2
        exit 1
    fi

    source_path="$REPO_ROOT/$source_rel"
    target_path="$(expand_path "$target_raw")"

    echo "Installing ($mode):"
    echo "  $source_path -> $target_path"

    mkdir -p "$(dirname "$target_path")"

    if [[ "$mode" == "copy" && -d "$source_path" && ! -L "$source_path" && -d "$target_path" && ! -L "$target_path" ]]; then
        copy_changed_directory "$source_path" "$target_path"
        continue
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        if [[ "$mode" == "link" ]]; then
            # Already correctly linked, skip silently
            if [[ -L "$target_path" && "$(readlink "$target_path")" == "$source_path" ]]; then
                echo "Already linked, skipping."
                continue
            fi
        elif [[ ! -L "$target_path" && -e "$source_path" && -e "$target_path" ]] && diff -qr "$source_path" "$target_path" >/dev/null; then
            echo "Already copied, skipping."
            continue
        fi

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

    if [[ "$mode" == "copy" ]]; then
        cp -a "$source_path" "$target_path"
    else
        ln -s "$source_path" "$target_path"
    fi
done

echo
echo "Done."

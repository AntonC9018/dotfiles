#!/usr/bin/env bash
set -euo pipefail
#TODO sudo, but write to user home, not sudo home?

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

MAPPINGS_FILE="$REPO_ROOT/mappings.json"

FORCE_ALL=0
FORCE_PATTERNS=()

usage() {
    cat <<'EOF'
Usage: symlinks.sh [OPTIONS]

Install symlinks/copies as configured in mappings.json.

Options:
  -f, --force [ENTRY...]        Force replace without prompting.
                               No ENTRY: force all entries.
                               With ENTRY (one or more): only force entries
                               whose source matches, e.g.:
                                 symlinks.sh --force agent-config
                                 symlinks.sh --force agent-config/AGENTS.md
                               An ENTRY matches exactly, as a parent directory
                               (agent-config matches agent-config/AGENTS.md),
                               as a glob (agent-*), or as a comma-separated list.
      --force-entry ENTRY       Force a single entry (repeatable).
                                Alias: --force-file, --force=ENTRY
  -h, --help                    Show this help.

Per-entry config (mappings.json):
  "agent-config/AGENTS.md": {
      "target": "~/.codex/AGENTS.md",
      "mode": "copy",
      "force": true
  }
  "force": true replaces without prompting for that entry.
  CLI --force overrides / extends the config.
EOF
}

add_force_patterns() {
    local raw="$1"
    local part
    local -a __parts
    IFS=',' read -ra __parts <<< "$raw"
    for part in "${__parts[@]}"; do
        # trim whitespace
        part="${part#"${part%%[![:space:]]*}"}"
        part="${part%"${part##*[![:space:]]}"}"
        [[ -n "$part" ]] && FORCE_PATTERNS+=("$part")
    done
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -f|--force)
            shift
            # Optional entry names after the flag: --force ENTRY...
            _collected=0
            while [[ $# -gt 0 && "$1" != -* ]]; do
                add_force_patterns "$1"
                _collected=1
                shift
            done
            if [[ "$_collected" -eq 0 ]]; then
                FORCE_ALL=1
            fi
            ;;
        --force-entry|--force-file)
            if [[ $# -lt 2 ]]; then
                echo "Option $1 requires an argument." >&2
                exit 1
            fi
            add_force_patterns "$2"
            shift 2
            ;;
        --force-entry=*|--force-file=*|--force=*)
            add_force_patterns "${1#*=}"
            shift
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                add_force_patterns "$1"
                shift
            done
            ;;
        -*)
            echo "Unknown option: $1 (see --help)" >&2
            exit 1
            ;;
        *)
            echo "Unexpected argument: $1 (see --help)" >&2
            exit 1
            ;;
    esac
done

# True if the given mapping source (e.g. "agent-config/AGENTS.md")
# was selected via --force ENTRY... / --force-entry.
matches_force_pattern() {
    local source_rel="$1"
    local pattern
    for pattern in "${FORCE_PATTERNS[@]}"; do
        if [[ "$source_rel" == "$pattern" ]]; then
            return 0
        fi
        if [[ "$source_rel" == "$pattern"/* ]]; then
            return 0
        fi
        case "$pattern" in
            *\** | *\?* | *\[*)
                # shellcheck disable=SC2053
                if [[ "$source_rel" == $pattern ]]; then
                    return 0
                fi
                ;;
        esac
    done
    return 1
}

# Whether this entry replaces without prompting:
# global --force, matching --force ENTRY, or "force": true in mappings.json.
should_force_entry() {
    local source_rel="$1"
    local config_force="$2" # "true" or "false"
    if [[ "$FORCE_ALL" -eq 1 ]]; then
        return 0
    fi
    if [[ "$config_force" == "true" ]]; then
        return 0
    fi
    if matches_force_pattern "$source_rel"; then
        return 0
    fi
    return 1
}

# Set to 1 while installing a forced top-level entry so the recursive
# copy helper skips its inner prompts as well.
FORCE_CURRENT_ENTRY=0

replace_confirmed() {
    # $1 = message to print about what is being replaced
    local message="$1"
    if [[ "$FORCE_CURRENT_ENTRY" -eq 1 ]]; then
        echo "Force replacing: $message"
        return 0
    fi
    confirm "Replace it?"
}

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
    local reply
    # Read from the terminal (not stdin): stdin is the mappings pipe,
    # so reading the answer from stdin would swallow mapping entries.
    # Without a terminal, treat as declined (silently).
    printf '%s [y/N]: ' "$prompt" >&2
    # Grouped so the redirection failure is silenced when no terminal exists.
    if ! { read -r reply </dev/tty; } 2>/dev/null; then
        printf '\n' >&2
        return 1
    fi
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
                if ! replace_confirmed "$target_entry"; then
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
            if ! replace_confirmed "$target_entry"; then
                echo "Skipped."
                continue
            fi
            rm -rf "$target_entry"
        elif [[ -e "$target_entry" || -L "$target_entry" ]]; then
            echo "Warning: target already exists: $target_entry"
            if [[ -L "$target_entry" ]]; then
                echo "It is a symlink pointing to: $(readlink "$target_entry")"
            fi
            if ! replace_confirmed "$target_entry"; then
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
    config_force="$(_jq 'if (.value | type) == "object" then ((.value.force // false) | tostring) else "false" end')"

    if [[ "$mode" != "link" && "$mode" != "copy" ]]; then
        echo "Unsupported mapping mode '$mode' for $source_rel" >&2
        exit 1
    fi

    if [[ "$config_force" != "true" && "$config_force" != "false" ]]; then
        echo "Unsupported force value '$config_force' for $source_rel (expected true/false)" >&2
        exit 1
    fi

    FORCE_CURRENT_ENTRY=0
    if should_force_entry "$source_rel" "$config_force"; then
        FORCE_CURRENT_ENTRY=1
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

        if ! replace_confirmed "$target_path"; then
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

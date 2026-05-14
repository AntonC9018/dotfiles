#!/usr/bin/env bash

# Prevent re-prompting if this file is sourced multiple times in the same session
if [[ -n "${WINDOWS_USER_DIR:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi

DEFAULT_WINDOWS_USER="Anton"
WINDOWS_USERS_ROOT="/mnt/c/Users"
DEFAULT_WINDOWS_USER_DIR="$WINDOWS_USERS_ROOT/$DEFAULT_WINDOWS_USER"

# Export this so it can be reused by the scripts that source it
export PROMPT_PREFIX="> "

while true; do
    if [[ -d "$DEFAULT_WINDOWS_USER_DIR" ]]; then
        export WINDOWS_USER_DIR="$DEFAULT_WINDOWS_USER_DIR"
        break
    fi

    echo "Default Windows user directory not found:"
    echo "  $DEFAULT_WINDOWS_USER_DIR"
    echo
    echo "Enter either:"
    echo "  - a Windows username (example: $DEFAULT_WINDOWS_USER)"
    echo "  - or a full path to your Windows user directory"

    read -rp "$PROMPT_PREFIX" USER_INPUT

    # If input contains '/', treat it as a path
    if [[ "$USER_INPUT" == *"/"* ]]; then
        WINDOWS_USER_DIR="$USER_INPUT"
    else
        WINDOWS_USER_DIR="$WINDOWS_USERS_ROOT/$USER_INPUT"
    fi

    if [[ -d "$WINDOWS_USER_DIR" ]]; then
        export WINDOWS_USER_DIR
        break
    fi

    echo
    echo "Windows user directory does not exist:"
    echo "  $WINDOWS_USER_DIR"
    echo
done

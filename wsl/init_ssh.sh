#!/usr/bin/env bash
set -euo pipefail

# -e            exit immediately if a command fails
# -u            error on unset variables
# -o pipefail   fail pipeline if any command fails

# Resolve the directory of THIS script, not the current working directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared user resolution logic
source "$SCRIPT_DIR/resolve_windows_user.sh"

SSH_DIR="$HOME/.ssh"
WINDOWS_SSH_DIR="$WINDOWS_USER_DIR/.ssh"
DEFAULT_KEY_NAME="github_wsl"

# Permission constants
SSH_DIR_PERMS=700
PRIVATE_KEY_PERMS=600
PUBLIC_KEY_PERMS=644

# Build paths
key_src_path() {
    local key_name="$1"
    printf '%s/%s' "$WINDOWS_SSH_DIR" "$key_name"
}

key_pub_src_path() {
    local key_name="$1"
    printf '%s/%s.pub' "$WINDOWS_SSH_DIR" "$key_name"
}

key_dst_path() {
    local key_name="$1"
    printf '%s/%s' "$SSH_DIR" "$key_name"
}

key_pub_dst_path() {
    local key_name="$1"
    printf '%s/%s.pub' "$SSH_DIR" "$key_name"
}

mkdir -p "$SSH_DIR"
chmod "$SSH_DIR_PERMS" "$SSH_DIR"

if [[ ! -d "$WINDOWS_SSH_DIR" ]]; then
    echo "Error: Windows SSH directory does not exist:"
    echo "  $WINDOWS_SSH_DIR"
    exit 1
fi

# Resolve SSH key
while true; do
    KEY_NAME="${DEFAULT_KEY_NAME:-}"

    if [[ -n "$KEY_NAME" ]] && [[ -f "$(key_src_path "$KEY_NAME")" ]]; then
        echo "Using default key:"
        echo "  $KEY_NAME"
    else
        echo
        echo "Default key '$DEFAULT_KEY_NAME' not found."
        echo
        echo "Available private keys:"

        find "$WINDOWS_SSH_DIR" \
            -maxdepth 1 \
            -type f \
            ! -name "*.pub" \
            -printf "  %f\n"

        echo
        echo "Enter SSH key name:"

        read -rp "$PROMPT_PREFIX" KEY_NAME
    fi

    PRIVATE_KEY_SRC="$(key_src_path "$KEY_NAME")"
    PUBLIC_KEY_SRC="$(key_pub_src_path "$KEY_NAME")"

    PRIVATE_KEY_DST="$(key_dst_path "$KEY_NAME")"
    PUBLIC_KEY_DST="$(key_pub_dst_path "$KEY_NAME")"

    if [[ -f "$PRIVATE_KEY_SRC" ]]; then
        break
    fi

    echo
    echo "Private key not found:"
    echo "  $PRIVATE_KEY_SRC"
    echo

    # Prevent infinite auto-loop if default key is missing
    DEFAULT_KEY_NAME=""
done

# Copy private key
cp "$PRIVATE_KEY_SRC" "$PRIVATE_KEY_DST"
chmod "$PRIVATE_KEY_PERMS" "$PRIVATE_KEY_DST"

# Copy public key if present
if [[ -f "$PUBLIC_KEY_SRC" ]]; then
    cp "$PUBLIC_KEY_SRC" "$PUBLIC_KEY_DST"
    chmod "$PUBLIC_KEY_PERMS" "$PUBLIC_KEY_DST"
else
    echo
    echo "Warning: public key not found:"
    echo "  $PUBLIC_KEY_SRC"
fi

echo
echo "SSH key installed successfully:"
echo "  Private key: $PRIVATE_KEY_DST"

if [[ -f "$PUBLIC_KEY_DST" ]]; then
    echo "  Public key : $PUBLIC_KEY_DST"
fi

exit 0

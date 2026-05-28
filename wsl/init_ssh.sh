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
AWS_KEY_NAME="aws_coding.pem"

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

copy_key() {
    local key_name="$1"

    local private_src
    local public_src
    local private_dst
    local public_dst

    private_src="$(key_src_path "$key_name")"
    public_src="$(key_pub_src_path "$key_name")"

    private_dst="$(key_dst_path "$key_name")"
    public_dst="$(key_pub_dst_path "$key_name")"

    if [[ ! -f "$private_src" ]]; then
        echo
        echo "Warning: private key not found:"
        echo "  $private_src"
        return 1
    fi

    cp "$private_src" "$private_dst"
    chmod "$PRIVATE_KEY_PERMS" "$private_dst"

    if [[ -f "$public_src" ]]; then
        cp "$public_src" "$public_dst"
        chmod "$PUBLIC_KEY_PERMS" "$public_dst"
    else
        echo
        echo "Warning: public key not found:"
        echo "  $public_src"
    fi

    echo
    echo "SSH key installed successfully:"
    echo "  Private key: $private_dst"

    if [[ -f "$public_dst" ]]; then
        echo "  Public key : $public_dst"
    fi
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

    if [[ -f "$(key_src_path "$KEY_NAME")" ]]; then
        break
    fi

    echo
    echo "Private key not found:"
    echo "  $(key_src_path "$KEY_NAME")"
    echo

    # Prevent infinite auto-loop if default key is missing
    DEFAULT_KEY_NAME=""
done

# Copy selected SSH key
copy_key "$KEY_NAME"

# Copy AWS PEM key
copy_key "$AWS_KEY_NAME" || true

exit 0

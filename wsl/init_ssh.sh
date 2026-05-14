#!/usr/bin/env bash
set -euo pipefail

# -e            exit immediately if a command fails
# -u            error on unset variables
# -o pipefail   fail pipeline if any command fails

SSH_DIR="$HOME/.ssh"

DEFAULT_WINDOWS_USER="Anton"
DEFAULT_KEY_NAME="github_wsl"

WINDOWS_USERS_ROOT="/mnt/c/Users"
DEFAULT_WINDOWS_SSH_DIR="$WINDOWS_USERS_ROOT/$DEFAULT_WINDOWS_USER/.ssh"

# Permission constants
# owner = rwx
# group = ---
# others = ---
SSH_DIR_PERMS=700
# owner = rw-
# group = ---
# others = ---
PRIVATE_KEY_PERMS=600
# owner = rw-
# group = r--
# others = r--
PUBLIC_KEY_PERMS=644

PROMPT_PREFIX="> "

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

# -p : create parent directories if needed,
#      do nothing if directory already exists
mkdir -p "$SSH_DIR"

chmod "$SSH_DIR_PERMS" "$SSH_DIR"

# Resolve Windows SSH directory
while true; do
    if [[ -d "$DEFAULT_WINDOWS_SSH_DIR" ]]; then
        WINDOWS_SSH_DIR="$DEFAULT_WINDOWS_SSH_DIR"
        break
    fi

    echo "Default Windows SSH directory not found:"
    echo "  $DEFAULT_WINDOWS_SSH_DIR"
    echo
    echo "Enter either:"
    echo "  - a Windows username (example: $DEFAULT_WINDOWS_USER)"
    echo "  - or a full path to the .ssh directory"

    read -rp "$PROMPT_PREFIX" USER_INPUT

    # If input contains '/', treat it as a path
    if [[ "$USER_INPUT" == *"/"* ]]; then
        WINDOWS_SSH_DIR="$USER_INPUT"
    else
        WINDOWS_SSH_DIR="$WINDOWS_USERS_ROOT/$USER_INPUT/.ssh"
    fi

    if [[ -d "$WINDOWS_SSH_DIR" ]]; then
        break
    fi

    echo
    echo "SSH directory does not exist:"
    echo "  $WINDOWS_SSH_DIR"
    echo
done

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

#
# SSH refuses private keys with loose permissions.
chmod "$PRIVATE_KEY_PERMS" "$PRIVATE_KEY_DST"

# Copy public key if present
if [[ -f "$PUBLIC_KEY_SRC" ]]; then
    cp "$PUBLIC_KEY_SRC" "$PUBLIC_KEY_DST"

    #
    # Public keys are not secret.
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

# Remove old github.com entries to avoid "Host key verification failed" errors
ssh-keygen -R github.com 2>/dev/null
# Scan and add the current GitHub keys to known_hosts
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

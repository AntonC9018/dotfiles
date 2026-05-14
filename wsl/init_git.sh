#!/usr/bin/env bash
set -euo pipefail

# Resolve the directory of THIS script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source the shared user resolution logic
source "$SCRIPT_DIR/resolve_windows_user.sh"

WINDOWS_GITCONFIG="$WINDOWS_USER_DIR/.gitconfig"
LINUX_GITCONFIG="$HOME/.gitconfig"

echo
echo "Setting up Git configuration..."

if [[ -f "$WINDOWS_GITCONFIG" ]]; then
    cp "$WINDOWS_GITCONFIG" "$LINUX_GITCONFIG"
    
    # Optional: ensure correct permissions on the copied file
    chmod 644 "$LINUX_GITCONFIG"
    
    echo "Successfully copied .gitconfig from Windows to WSL:"
    echo "  $LINUX_GITCONFIG"
else
    echo "Warning: .gitconfig not found at:"
    echo "  $WINDOWS_GITCONFIG"
fi
exit 0

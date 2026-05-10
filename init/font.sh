#!/usr/bin/env bash
set -euo pipefail

# Installs SauceCodePro Nerd Font on Ubuntu WSL
# and configures fontconfig for Linux terminal apps.

FONT_NAME="SauceCodePro"
VERSION="3.3.0"
ZIP_NAME="${FONT_NAME}.zip"
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${VERSION}/${ZIP_NAME}"

FONT_DIR="$HOME/.local/share/fonts/${FONT_NAME}"
TMP_DIR="$(mktemp -d)"

echo "Installing ${FONT_NAME} Nerd Font..."

mkdir -p "$FONT_DIR"

cd "$TMP_DIR"

echo "Downloading font..."
curl -fLo "$ZIP_NAME" "$DOWNLOAD_URL"

echo "Extracting..."
unzip -o "$ZIP_NAME" -d extracted >/dev/null

echo "Copying font files..."
find extracted -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONT_DIR" \;

echo "Refreshing font cache..."
fc-cache -fv >/dev/null

echo
echo "Installed fonts:"
fc-list | grep -i "SauceCodePro" || true

rm -rf "$TMP_DIR"
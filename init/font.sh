#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="SauceCodePro"
ARCHIVE_NAME="SourceCodePro"          # actual filename on GitHub releases
FONT_DIR="$HOME/.local/share/fonts/${FONT_NAME}"
TMP_DIR="$(mktemp -d)"

echo "Installing ${FONT_NAME} Nerd Font..."
mkdir -p "$FONT_DIR"
cd "$TMP_DIR"

echo "Downloading font..."
curl -fLo font.tar.xz \
  "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${ARCHIVE_NAME}.tar.xz"

echo "Extracting..."
tar -xf font.tar.xz

echo "Copying font files..."
find . -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec cp {} "$FONT_DIR" \;

echo "Refreshing font cache..."
fc-cache -fv >/dev/null

echo
echo "Installed fonts:"
fc-list | grep -i "SauceCodePro" || true

rm -rf "$TMP_DIR"
set -euo pipefail

nvim_with_version="nvim-linux-x86_64"
install_dir="$HOME/nvim"

if [[ -x "$install_dir/bin/nvim" ]]; then
    echo "Neovim already installed at $install_dir, skipping."
else
    wget "https://github.com/neovim/neovim/releases/download/nightly/$nvim_with_version.tar.gz" -O nvim.tar.gz

    tar -xf nvim.tar.gz

    rm -rf "$install_dir"
    mv "$nvim_with_version" "$install_dir"

    rm nvim.tar.gz

    echo "Neovim installed."
fi

if command -v tree-sitter >/dev/null 2>&1; then
    echo "tree-sitter-cli already installed, skipping."
else
    cargo install tree-sitter-cli
fi
set -euo pipefail

nvim_with_version="nvim-linux-x86_64"
wget "https://github.com/neovim/neovim/releases/download/nightly/$nvim_with_version.tar.gz" -O nvim.tar.xz
tar -xf nvim.tar.xz
mv "$nvim_with_version" ~/nvim
rm nvim.tar.xz
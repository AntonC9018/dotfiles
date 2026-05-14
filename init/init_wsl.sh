set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cp ../wsl/init_windows_host.sh $HOME/init_windows_host
bash ../wsl/init_init_windows_host.sh

bash ./apt.sh
bash ./zig.sh
bash ./llvm_fix.sh
bash ./font.sh
bash ./zsh.sh
bash ../wsl/init_ssh.sh
bash ./git.sh
bash ./nvim.sh
bash ./symlinks.sh

zsh -c '
    source ~/.zshrc
    git submodule update --init --recursive --depth 1
    https_to_ssh
    exec zsh
'

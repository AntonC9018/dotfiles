set -euo pipefail

cp ../wsl/init_windows_host.sh $HOME/init_windows_host
bash ../wsl/init_init_windows_host.sh

bash ./apt.sh
bash ./zig.sh
bash ./llvm_fix.sh
bash ./font.sh
bash ./symlinks.sh
bash ./zsh.sh
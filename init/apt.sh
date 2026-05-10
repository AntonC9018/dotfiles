set -euo pipefail

sudo apt-get update
sudo apt install -y curl gnupg
sudo apt-get update software-properties-common
echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/llvm.list
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | \
sudo gpg --dearmor -o /usr/share/keyrings/llvm.gpg

sudo add-apt-repository ppa:deadsnakes/ppa
sudo add-apt-repository ppa:george-edison55/cmake-3.x
sudo add-apt-repository ppa:neovim-ppa/unstable
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

sudo apt-get install jq neovim rustc go cmake fzf ripgrep python3-lldb-17 clang-17 lldb-17 lld-17
sudo apt-get upgrade
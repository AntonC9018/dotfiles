set -euo pipefail

LLVM_CODENAME="noble"  # or "jammy" for Ubuntu 22.04

sudo apt-get update -y
sudo apt install -y curl gnupg software-properties-common
sudo mkdir -p /usr/share/keyrings
echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/${LLVM_CODENAME}/ llvm-toolchain-${LLVM_CODENAME} main" | sudo tee /etc/apt/sources.list.d/llvm.list
curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | \
sudo gpg --dearmor --yes -o /usr/share/keyrings/llvm.gpg

sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get update -y

sudo apt-get install -y jq rustc cmake golang-go fzf ripgrep python3-lldb-17 clang-17 lldb-17 lld-17 zsh cargo nodejs gdb unzip
sudo apt-get upgrade -y


set -euo pipefail

# https://github.com/llvm/llvm-project/issues/55575#issuecomment-1247426995
ln -s /usr/lib/llvm-14/lib/python3.10/dist-packages/lldb/* /usr/lib/python3/dist-packages/lldb/

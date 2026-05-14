set -euo pipefail

# https://github.com/llvm/llvm-project/issues/55575#issuecomment-1247426995
src_dir="/usr/lib/llvm-14/lib/python3.10/dist-packages/lldb"
dst_dir="/usr/lib/python3/dist-packages/lldb"

sudo mkdir -p "$dst_dir"

for f in "$src_dir"/*; do
    [ -e "$f" ] || continue

    name="$(basename "$f")"
    target="$dst_dir/$name"

    # skip if already exists (file or symlink)
    if [ -e "$target" ] || [ -L "$target" ]; then
        continue
    fi

    sudo ln -s "$f" "$target"
done
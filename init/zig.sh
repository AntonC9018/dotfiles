set -euo pipefail

zig_version="0.16.0"
zig_with_version="zig-x86_64-linux-$zig_version"
install_dir="$HOME/zig"

if [[ -x "$install_dir/zig" ]]; then
    installed_version="$("$install_dir/zig" version 2>/dev/null || true)"

    if [[ "$installed_version" == "$zig_version" ]]; then
        echo "Zig $zig_version is already installed, skipping."
        exit 0
    else
        echo "Different Zig version detected ($installed_version), reinstalling..."
        rm -rf "$install_dir"
    fi
fi

wget "https://ziglang.org/download/$zig_version/$zig_with_version.tar.xz" -O zig.tar.xz
tar -xf zig.tar.xz

mv "$zig_with_version" "$install_dir"
rm zig.tar.xz

echo "Installed Zig $zig_version"
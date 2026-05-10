set -euo pipefail

zig_version="0.16.0"
zig_with_version="zig-linux-x86_64-$zig_version"
wget https://ziglang.org/download/$zig_version/$zig_with_version.tar.xz -O zig.tar.xz
tar -xf zig.tar.xz
mv "$zig_with_version" zig
rm zig.tar.xz
#!/usr/bin/env bash
# Copyright 2026 Dicer Authors
# SPDX-License-Identifier: MIT
#
# Builds Dicer's guest kernel for one architecture: the kernel.org release in
# kernel.env, configured with Cloud Hypervisor's configuration and
# dicer.config on top.
#
#   ./build.sh x86_64|arm64 OUT
#
# OUT receives the kernel (vmlinux-x86_64 or Image-arm64) and its final
# configuration (config-x86_64 or config-arm64). It builds natively: run it on
# a machine of the architecture it builds for.
set -euo pipefail

arch=${1:?usage: build.sh x86_64|arm64 OUT}
out=${2:?usage: build.sh x86_64|arm64 OUT}
here=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=kernel.env
source "$here/kernel.env"

case $arch in
x86_64) target=vmlinux image=vmlinux name=vmlinux-x86_64 ;;
arm64) target=Image image=arch/arm64/boot/Image name=Image-arm64 ;;
*) echo "unknown architecture $arch: want x86_64 or arm64" >&2; exit 1 ;;
esac

mkdir -p "$out"
out=$(cd "$out" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

tarball=linux-$LINUX_VERSION.tar.xz
major=${LINUX_VERSION%%.*}
if [[ ! -f $here/$tarball ]]; then
  curl -fsSL -o "$here/$tarball" "https://cdn.kernel.org/pub/linux/kernel/v$major.x/$tarball"
fi
echo "$LINUX_SHA256  $here/$tarball" | sha256sum --check --quiet
tar -xJf "$here/$tarball" -C "$work"
src=$work/linux-$LINUX_VERSION

cp "$here/configs/ch-$arch.config" "$src/.config"
(cd "$src" && ./scripts/kconfig/merge_config.sh -m .config "$here/dicer.config" >/dev/null)
make -C "$src" olddefconfig >/dev/null

# merge_config.sh only warns when an option cannot be set; missing one would
# leave a kernel Dicer cannot boot, so fail instead.
missing=0
while IFS= read -r line; do
  [[ $line =~ ^CONFIG_ ]] || continue
  if ! grep -qxF "$line" "$src/.config"; then
    echo "dicer.config: $line did not survive into the kernel's configuration" >&2
    missing=1
  fi
done <"$here/dicer.config"
((missing == 0)) || exit 1

make -C "$src" -j"$(nproc)" "$target"
cp "$src/$image" "$out/$name"
cp "$src/.config" "$out/config-$arch"
echo "built $out/$name"

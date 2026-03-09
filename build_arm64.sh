#!/bin/sh
set -e

SYSROOT="$HOME/x-tools/aarch64-buildroot-linux-gnu/aarch64-buildroot-linux-gnu/sysroot"
export PATH="$HOME/x-tools/aarch64-buildroot-linux-gnu/bin:$PATH"
export CROSS_COMPILE="$HOME/x-tools/aarch64-buildroot-linux-gnu/bin/aarch64-buildroot-linux-gnu-"

export CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
export CXXFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
export CPPFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include"
export LDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib -L$SYSROOT/lib"

cd "$(dirname "$0")"

# Clean previous build artifacts
rm -rf bin/

# Build stage first (no LTO to avoid PIC issues)
echo "=== Building stage ==="
make -C stage clean 2>/dev/null || true
make -C stage DEVICE=ARM64_A53 DEBUG=2 \
  CROSS_COMPILE="$CROSS_COMPILE" \
  CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include -mcpu=cortex-a53 -mtune=cortex-a53 -mfix-cortex-a53-835769 -mfix-cortex-a53-843419 -O2 -pipe -ffunction-sections -fdata-sections -Wall -Wno-format-zero-length -Wno-unused-function -fno-plt -fno-stack-protector -fno-ident -fPIC" \
  LDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib -shared -Wl,--strip-all -ldl -lSDL2 -lSDL2_image -lGLESv2"

echo "=== Building dependencies ==="
for DEP in common font lvgl lookup module; do
  echo "Building: $DEP"
  make -C "$DEP" DEVICE=ARM64_A53 DEBUG=2 \
    CROSS_COMPILE="$CROSS_COMPILE" \
    CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include -mcpu=cortex-a53 -mtune=cortex-a53 -mfix-cortex-a53-835769 -mfix-cortex-a53-843419 -O2 -pipe -ffunction-sections -fdata-sections -Wall -Wno-format-zero-length -Wno-unused-function -fno-plt -fno-stack-protector -fno-ident" \
    LDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib"
done

echo "=== Building modules ==="
make DEVICE=ARM64_A53 DEBUG=2 \
  CROSS_COMPILE="$CROSS_COMPILE" \
  CFLAGS="--sysroot=$SYSROOT -I$SYSROOT/usr/include -mcpu=cortex-a53 -mtune=cortex-a53 -mfix-cortex-a53-835769 -mfix-cortex-a53-843419 -O2 -pipe -flto=auto -ffunction-sections -fdata-sections -Wall -Wno-format-zero-length -Wno-unused-function -fno-plt -fno-stack-protector -fno-ident" \
  LDFLAGS="--sysroot=$SYSROOT -L$SYSROOT/usr/lib"

echo "=== Build complete ==="
ls -la bin/

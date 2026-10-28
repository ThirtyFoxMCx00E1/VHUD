#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source work/prebuilt.env
ABIS=""
[ -n "$PREBUILT_32" ] || ABIS="$ABIS armeabi-v7a"
[ -n "$PREBUILT_64" ] || ABIS="$ABIS arm64-v8a"
ABIS="${ABIS# }"
if [ -z "$ABIS" ]; then echo "libVHUD32.so and libVHUD64.so were both uploaded - nothing to compile for VHUD."; exit 0; fi
echo "Compiling VHUD from source for: $ABIS"
cd work/VHUD
ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk NDK_APPLICATION_MK=./Application.mk APP_ABI="$ABIS" NDK_DEBUG=0 -j"$(nproc)"

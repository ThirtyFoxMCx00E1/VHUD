#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source work/prebuilt.env
D=dist
mkdir -p $D/armeabi-v7a $D/arm64-v8a
: > $D/BUILD_INFO.txt

req() { [ -f "$1" ] || { echo "::error::expected build output missing: $1"; exit 1; }; cp "$1" "$2"; echo "$(basename "$1")  <- built from source" >> $D/BUILD_INFO.txt; }
opt() { if [ -f "$1" ]; then cp "$1" "$2"; echo "$(basename "$1")  <- built from source" >> $D/BUILD_INFO.txt; else echo "::warning::optional output missing: $1"; fi; }

req work/AML/libs/armeabi-v7a/libAML.so $D/armeabi-v7a/
req work/AML/libs/arm64-v8a/libAML.so   $D/arm64-v8a/
opt work/SAUtils/libs/armeabi-v7a/libSAUtils.so   $D/armeabi-v7a/
opt work/SAUtils/libs/arm64-v8a/libSAUtils64.so   $D/arm64-v8a/
opt work/ImGui/jni/libs/armeabi-v7a/libDearImGui.so $D/armeabi-v7a/

# VHUD: an uploaded lib wins over a source build, but its ELF type is checked first.
if [ -n "$PREBUILT_32" ]; then
  file "$PREBUILT_32" | grep -q '32-bit.*ARM' || { echo "::error::$PREBUILT_32 is not a 32-bit ARM library"; exit 1; }
  cp "$PREBUILT_32" $D/armeabi-v7a/libVHUD32.so; echo "libVHUD32.so  <- uploaded ($PREBUILT_32)" >> $D/BUILD_INFO.txt
else req work/VHUD/libs/armeabi-v7a/libVHUD32.so $D/armeabi-v7a/; fi
if [ -n "$PREBUILT_64" ]; then
  file "$PREBUILT_64" | grep -q 'ARM aarch64' || { echo "::error::$PREBUILT_64 is not an arm64 library"; exit 1; }
  cp "$PREBUILT_64" $D/arm64-v8a/libVHUD64.so; echo "libVHUD64.so  <- uploaded ($PREBUILT_64)" >> $D/BUILD_INFO.txt
else req work/VHUD/libs/arm64-v8a/libVHUD64.so $D/arm64-v8a/; fi

# Game-side assets from the upstream repo (textures, fonts, xml ...), if it was cloned.
if [ -d external/v-hud/resources ]; then mkdir -p $D/VHud-assets && cp -a external/v-hud/resources/. $D/VHud-assets/; fi

( cd $D && find . -name '*.so' -type f -exec sha256sum {} + ) >> $D/BUILD_INFO.txt
cat $D/BUILD_INFO.txt

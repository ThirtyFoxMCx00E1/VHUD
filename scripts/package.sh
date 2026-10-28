#!/usr/bin/env bash
# Builds dist/ so that it mirrors the phone:  mods/  -> Android/data/<pkg>/mods/   files/ -> Android/data/<pkg>/files/
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source work/prebuilt.env
D=dist
rm -rf $D
mkdir -p $D/mods $D/files $D/loader/armeabi-v7a $D/loader/arm64-v8a
: > $D/BUILD_INFO.txt
log() { echo "$1" >> $D/BUILD_INFO.txt; }

req() { [ -f "$1" ] || { echo "::error::expected build output missing: $1"; exit 1; }; cp "$1" "$2"; log "$(basename "$1")  <- built from source"; }
opt() { if [ -f "$1" ]; then cp "$1" "$2"; log "$(basename "$1")  <- built from source"; else echo "::warning::expected build output missing: $1"; fi; }
find_uploaded() { find . \( -path ./work -o -path ./dist -o -path ./external -o -path ./.git \) -prune -o -type f -name "$1" -print -quit; }

# AML loader (not a mod: goes into the APK, see mods/INSTALL.md step 4)
req work/AML/libs/armeabi-v7a/libAML.so $D/loader/armeabi-v7a/
req work/AML/libs/arm64-v8a/libAML.so   $D/loader/arm64-v8a/

# SAUtils: built if the private structs were available, else an uploaded lib is used, else skipped on purpose.
sautils() {  # sautils <lib file> <abi>
  local lib="$1" abi="$2" up
  if [ -f "work/SAUtils/libs/$abi/$lib" ]; then
    cp "work/SAUtils/libs/$abi/$lib" $D/mods/; log "$lib  <- built from source"; return 0
  fi
  up="$(find_uploaded "$lib")"
  if [ -n "$up" ]; then
    cp "$up" $D/mods/; log "$lib  <- uploaded ($up)"; return 0
  fi
  if grep -qw "$abi" work/sautils_abis.txt 2>/dev/null; then
    echo "::warning::SAUtils should have built for $abi but $lib is missing - check the SAUtils step log"
  else
    echo "::notice::$lib not included: SAUtils needs the private GTASA_STRUCTS headers (build skipped). Upload a prebuilt $lib to include it."
    log "$lib  <- not included (needs GTASA_STRUCTS headers or an uploaded lib)"
  fi
}
sautils libSAUtils.so   armeabi-v7a
sautils libSAUtils64.so arm64-v8a

opt work/ImGui/jni/libs/armeabi-v7a/libDearImGui.so $D/mods/

# VHUD: an uploaded lib wins over a source build, but its ELF type is checked first.
if [ -n "$PREBUILT_32" ]; then
  file "$PREBUILT_32" | grep -q '32-bit.*ARM' || { echo "::error::$PREBUILT_32 is not a 32-bit ARM library"; exit 1; }
  cp "$PREBUILT_32" $D/mods/libVHUD32.so; log "libVHUD32.so  <- uploaded ($PREBUILT_32)"
else req work/VHUD/libs/armeabi-v7a/libVHUD32.so $D/mods/; fi
if [ -n "$PREBUILT_64" ]; then
  file "$PREBUILT_64" | grep -q 'ARM aarch64' || { echo "::error::$PREBUILT_64 is not an arm64 library"; exit 1; }
  cp "$PREBUILT_64" $D/mods/libVHUD64.so; log "libVHUD64.so  <- uploaded ($PREBUILT_64)"
else req work/VHUD/libs/arm64-v8a/libVHUD64.so $D/mods/; fi

# Assets -> files/VHud : upstream resources first, then your own assets/ on top.
mkdir -p $D/files/VHud
if [ -d external/v-hud/resources ]; then cp -a external/v-hud/resources/. $D/files/VHud/; log "files/VHud  <- external/v-hud/resources"; else echo "::notice::external/v-hud/resources not found, files/VHud only has your assets/"; fi
if [ -d assets ]; then cp -a assets/. $D/files/VHud/; rm -f $D/files/VHud/README.md; fi

# Tutorial next to the libraries
cp templates/INSTALL.md $D/mods/INSTALL.md

( cd $D && find mods loader -name '*.so' -type f -exec sha256sum {} + ) >> $D/BUILD_INFO.txt
cat $D/BUILD_INFO.txt

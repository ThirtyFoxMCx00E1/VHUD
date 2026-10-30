#!/usr/bin/env bash
# dist/ mirrors the phone:  mods/ -> Android/data/<pkg>/mods/    files/ -> Android/data/<pkg>/files/
# The optional tools build (BUILD_TOOLS=true) goes to dist/tools/ and is never part of mods/.
set -euo pipefail
cd "$(dirname "$0")/.."
# shellcheck disable=SC1091
source work/prebuilt.env
D=dist
rm -rf $D
mkdir -p $D/mods $D/files
: > $D/BUILD_INFO.txt
log() { echo "$1" >> $D/BUILD_INFO.txt; }
req() { [ -f "$1" ] || { echo "::error::expected build output missing: $1"; exit 1; }; cp "$1" "$2"; log "$(basename "$1")  <- built from source"; }
find_uploaded() { find . \( -path ./work -o -path ./dist -o -path ./external -o -path ./.git \) -prune -o -type f -name "$1" -print -quit; }

# ---------- VHUD: an uploaded lib wins over a source build, but its ELF type is checked first ----------
if [ -n "$PREBUILT_32" ]; then
  file "$PREBUILT_32" | grep -q '32-bit.*ARM' || { echo "::error::$PREBUILT_32 is not a 32-bit ARM library"; exit 1; }
  cp "$PREBUILT_32" $D/mods/libVHUD32.so; log "libVHUD32.so  <- uploaded ($PREBUILT_32)"
else req work/VHUD/libs/armeabi-v7a/libVHUD32.so $D/mods/; fi
if [ -n "$PREBUILT_64" ]; then
  file "$PREBUILT_64" | grep -q 'ARM aarch64' || { echo "::error::$PREBUILT_64 is not an arm64 library"; exit 1; }
  cp "$PREBUILT_64" $D/mods/libVHUD64.so; log "libVHUD64.so  <- uploaded ($PREBUILT_64)"
else req work/VHUD/libs/arm64-v8a/libVHUD64.so $D/mods/; fi

# ---------- Assets -> files/VHud : upstream resources first, then your own assets/ on top ----------
mkdir -p $D/files/VHud
if [ -d external/v-hud/resources ]; then cp -a external/v-hud/resources/. $D/files/VHud/; log "files/VHud  <- external/v-hud/resources"; else echo "::notice::external/v-hud/resources not found, files/VHud only has your assets/"; fi
if [ -d assets ]; then cp -a assets/. $D/files/VHud/; rm -f $D/files/VHud/README.md; fi

# ---------- Optional tools (not needed for the HUD) ----------
if [ "${BUILD_TOOLS:-false}" = true ]; then
  mkdir -p $D/tools/armeabi-v7a $D/tools/arm64-v8a
  # A libAML.so built from an older AML source has no earlyLaunchAMLCore: swapping it into the APK = black screen.
  aml_ok() { nm -D --defined-only "$1" 2>/dev/null | grep -q 'Java_net_rusjj_amlcore_earlyLaunchAMLCore'; }
  for abi in armeabi-v7a arm64-v8a; do
    src="work/AML/libs/$abi/libAML.so"
    [ -f "$src" ] || { echo "::error::expected build output missing: $src"; exit 1; }
    if aml_ok "$src"; then cp "$src" $D/tools/$abi/; log "tools/$abi/libAML.so  <- built from source (has earlyLaunchAMLCore)"
    else echo "::warning::libAML.so ($abi) from deps/AndroidModLoader is OLDER than the AML in your APK - not packaged. Do not swap it in."; log "tools/$abi/libAML.so  <- NOT packaged (older than the AML inside your APK)"; fi
  done
  sautils() {  # sautils <lib> <abi>
    local lib="$1" abi="$2" up
    if [ -f "work/SAUtils/libs/$abi/$lib" ]; then cp "work/SAUtils/libs/$abi/$lib" $D/tools/$abi/; log "tools/$abi/$lib  <- built from source"; return 0; fi
    up="$(find_uploaded "$lib")"
    if [ -n "$up" ]; then cp "$up" $D/tools/$abi/; log "tools/$abi/$lib  <- uploaded ($up)"; return 0; fi
    if grep -qw "$abi" work/sautils_abis.txt 2>/dev/null; then echo "::warning::SAUtils should have built for $abi but $lib is missing - check the SAUtils step log"
    else echo "::notice::$lib not included: SAUtils needs the private GTASA_STRUCTS headers (build skipped)."; fi
  }
  sautils libSAUtils.so   armeabi-v7a
  sautils libSAUtils64.so arm64-v8a
  if [ -f work/ImGui/jni/libs/armeabi-v7a/libDearImGui.so ]; then cp work/ImGui/jni/libs/armeabi-v7a/libDearImGui.so $D/tools/armeabi-v7a/; log "tools/armeabi-v7a/libDearImGui.so  <- built from source"
  else echo "::warning::ImGui plugin output missing"; fi
fi

cp templates/INSTALL.md $D/mods/INSTALL.md
( cd $D && find mods tools -name '*.so' -type f -exec sha256sum {} + 2>/dev/null ) >> $D/BUILD_INFO.txt || true
cat $D/BUILD_INFO.txt

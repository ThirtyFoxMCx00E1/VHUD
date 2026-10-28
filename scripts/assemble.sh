#!/usr/bin/env bash
# Builds work/{AML,SAUtils,ImGui,VHUD} from deps/ (vendored) + external/ (cloned).
set -euo pipefail
cd "$(dirname "$0")/.."

for d in external/ARMPatch external/AML_PrecompiledLibs; do
  [ -d "$d" ] || { echo "::error::$d missing - run scripts/fetch-deps.sh first"; exit 1; }
done
rm -rf work dist
mkdir -p work dist

# ---------- AML (+ ARMPatch + precompiled libs) ----------
cp -a deps/AndroidModLoader work/AML
rm -rf work/AML/ARMPatch work/AML/AML_PrecompiledLibs
cp -a external/ARMPatch work/AML/ARMPatch
cp -a external/AML_PrecompiledLibs work/AML/AML_PrecompiledLibs

# Overlay your newer ARMPatch.cpp/.h and ASM helper headers where the repo keeps them.
# ARMPatch.h includes "../AArchASMHelper/*.h" relative to itself, so create that dir next to it.
n=0
while IFS= read -r cpp; do
  dir="$(dirname "$cpp")"
  cp -v deps/ARMPatch-lib/ARMPatch.cpp "$dir/ARMPatch.cpp"
  cp -v deps/ARMPatch-lib/ARMPatch.h   "$dir/ARMPatch.h"
  mkdir -p "$dir/../AArchASMHelper"
  cp -v deps/ASMHelper-lib/*.h "$dir/../AArchASMHelper/"
  n=$((n+1))
done < <(find work/AML/ARMPatch -name ARMPatch.cpp -not -path '*/.git/*')
[ "$n" -gt 0 ] || { echo "::error::ARMPatch.cpp not found inside external/ARMPatch"; exit 1; }
[ -f work/AML/ARMPatch/armpatch_src/Android.mk ] || echo "::warning::ARMPatch/armpatch_src/Android.mk not found - the ARMPatch build step will fail"

# ---------- SAUtils ----------
cp -a deps/SAUtils work/SAUtils
cp -a work/AML/mod     work/SAUtils/mod
cp -a work/AML/include work/SAUtils/include
mkdir -p work/SAUtils/AArch64_ModHelper
cp deps/ASMHelper-lib/*.h work/SAUtils/AArch64_ModHelper/
# sautils*.cpp include GTASA_STRUCTS.h (32-bit) / GTASA_STRUCTS_210.h (64-bit): private structs.
# Looked up in deps/structs (yours), external/structs (private repo cloned over SSH) and the cloned repos.
find_hdr() { find deps/structs external/structs external/Psdk-aml external/AML_ImGui -type f -name "$1" -print -quit 2>/dev/null || true; }
SABIS=""
H32="$(find_hdr GTASA_STRUCTS.h)"
H64="$(find_hdr GTASA_STRUCTS_210.h)"
if [ -n "$H32" ]; then cp "$H32" work/SAUtils/GTASA_STRUCTS.h;     SABIS="armeabi-v7a"; fi
if [ -n "$H64" ]; then cp "$H64" work/SAUtils/GTASA_STRUCTS_210.h; SABIS="$SABIS arm64-v8a"; fi
echo "${SABIS# }" > work/sautils_abis.txt
echo "SAUtils ABIs with structs available: ${SABIS:-<none - SAUtils will be skipped>}"

# ---------- ImGui plugin ----------
mkdir -p work/ImGui
cp -a "deps/CLEO_ImGui/CLEO ImGui/jni" work/ImGui/jni
# RW/RenderWare.h does #include <aml-psdk/renderware/RwTexture.h>  ->  Psdk-aml must be reachable as ./aml-psdk
if [ -d external/Psdk-aml ]; then
  cp -a external/Psdk-aml work/ImGui/jni/aml-psdk && rm -rf work/ImGui/jni/aml-psdk/.git
  [ -f work/ImGui/jni/aml-psdk/renderware/RwTexture.h ] || echo "::warning::Psdk-aml/renderware/RwTexture.h not found - the ImGui build will probably fail"
  echo yes > work/imgui_ok.txt
else
  echo "::warning::Psdk-aml not cloned - ImGui plugin will be skipped"
fi

# ---------- VHUD (the port) ----------
mkdir -p work/VHUD
cp -a vhud/. work/VHUD/
cp -a work/AML/mod     work/VHUD/mod
cp -a work/AML/include work/VHUD/include
cp deps/SAUtils/isautils.h work/VHUD/
mkdir -p work/VHUD/AArchASMHelper && cp deps/ASMHelper-lib/*.h work/VHUD/AArchASMHelper/
if [ -d external/Psdk-aml ]; then cp -a external/Psdk-aml work/VHUD/psdk && rm -rf work/VHUD/psdk/.git; else echo "::warning::Psdk-aml not cloned"; fi

# ---------- uploaded prebuilt libs (anywhere in the repo) ----------
find_prebuilt() { find . \( -path ./work -o -path ./dist -o -path ./external -o -path ./.git \) -prune -o -type f -name "$1" -print -quit; }
P32="$(find_prebuilt libVHUD32.so || true)"
P64="$(find_prebuilt libVHUD64.so || true)"
{ echo "PREBUILT_32='$P32'"; echo "PREBUILT_64='$P64'"; } > work/prebuilt.env
echo "prebuilt libVHUD32.so: ${P32:-<none, will build from source>}"
echo "prebuilt libVHUD64.so: ${P64:-<none, will build from source>}"

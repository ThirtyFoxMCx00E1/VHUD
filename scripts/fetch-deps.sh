#!/usr/bin/env bash
# Clones the repos that are not vendored in deps/ into external/ (gitignored).
set -euo pipefail
cd "$(dirname "$0")/.."
OWNER="${OWNER:-ThirtyFoxMCx00E1}"
mkdir -p external

clone() {  # clone <name> <required|optional> [recurse]
  local name="$1" need="$2" recurse="${3:-}"
  if [ -n "$(ls -A "external/$name" 2>/dev/null)" ]; then echo "[skip] external/$name already present"; return 0; fi
  local url="https://github.com/$OWNER/$name.git"
  echo "[clone] $url"
  if [ -n "$recurse" ] && git clone --depth 1 --recurse-submodules --shallow-submodules "$url" "external/$name"; then return 0; fi
  rm -rf "external/$name"
  if git clone --depth 1 "$url" "external/$name"; then return 0; fi
  if [ "$need" = required ]; then echo "::error::could not clone $url"; exit 1; fi
  echo "::warning::could not clone optional repo $url"
}

clone ARMPatch            required recurse
clone AML_PrecompiledLibs required recurse
clone Psdk-aml            optional
clone v-hud               optional          # NOT recursive: its submodules are the Windows plugin-sdk
clone AML_ImGui           optional

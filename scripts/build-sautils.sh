#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ABIS="$(cat work/sautils_abis.txt 2>/dev/null || true)"
if [ -z "$ABIS" ]; then
  echo "::notice::SAUtils skipped: GTASA_STRUCTS.h / GTASA_STRUCTS_210.h not found. Put them in deps/structs/ or add the SSH secret (see README)."
  exit 0
fi
echo "Building SAUtils for: $ABIS"
cd work/SAUtils
ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk NDK_APPLICATION_MK=./Application.mk APP_ABI="$ABIS" NDK_DEBUG=0 -j"$(nproc)"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -f work/imgui_ok.txt ]; then echo "::notice::ImGui plugin skipped (Psdk-aml not cloned)"; exit 0; fi
cd work/ImGui/jni
ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=./Android.mk NDK_APPLICATION_MK=./Application.mk APP_PLATFORM=android-21 NDK_DEBUG=0 -j"$(nproc)"

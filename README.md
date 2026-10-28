# vhud-android

Monorepo that builds the AML tool chain and the V HUD mod for Android with the NDK in GitHub Actions.

## What the workflow does (`.github/workflows/build.yml`)
It runs on push (when `libVHUD32.so`, `libVHUD64.so`, `prebuilt/**`, `vhud/**`, `deps/**` or `scripts/**` change),
on pull requests, manually (Actions -> Run workflow) and on releases.

1. Clones the repos that are not vendored: `ARMPatch`, `AML_PrecompiledLibs`, `Psdk-aml`, `v-hud`, `AML_ImGui` (from `ThirtyFoxMCx00E1`).
2. Installs NDK r24 (same as your AML / SAUtils workflows).
3. Builds ARMPatch, **libAML.so** (armeabi-v7a + arm64-v8a), **libSAUtils.so / libSAUtils64.so**, the ImGui plugin (32-bit), and **VHUD**.
4. VHUD: if you committed `libVHUD32.so` and/or `libVHUD64.so` (anywhere in the repo, `prebuilt/armeabi-v7a/` and
   `prebuilt/arm64-v8a/` are the intended places), that ABI is **not** recompiled; the uploaded file is checked
   (32-bit ARM vs arm64) and packaged. Any ABI without an uploaded lib is compiled from `vhud/src`.
5. Uploads the artifact **VHUD-Android** (`armeabi-v7a/`, `arm64-v8a/`, `VHud-assets/`, `BUILD_INFO.txt` with SHA-256 and
   which libs were uploaded vs built). On a published release the zip is attached to the release.

SAUtils and the ImGui plugin are `continue-on-error`: if one fails, the rest still packages.
- **SAUtils** needs the private `GTASA_STRUCTS.h` / `GTASA_STRUCTS_210.h`. Drop them in `deps/structs/`, or add a repo
  secret named `SSH` (deploy key with access to `RusJJ/GTASAAndroid_Structs`). Without them SAUtils is skipped, not failed.
- **ImGui plugin** uses its own `RW/` headers (it no longer includes `aml-psdk`, which clashed with them).

## Layout
- `deps/` - your uploaded sources (AndroidModLoader, SAUtils, CLEO_ImGui, ARMPatch.cpp/.h, ASM helpers)
- `vhud/` - the Android port of V HUD (`src/`, `Android.mk`, `Application.mk`) - see `PORTING.md`
- `prebuilt/` - drop `libVHUD32.so` / `libVHUD64.so` here
- `scripts/` - `fetch-deps.sh`, `assemble.sh`, `build-vhud.sh`, `package.sh` (the same steps run locally if the NDK is on PATH)

## Not included on purpose
The game binaries from `arm64-v8a.zip` / `armeabi-v7a.zip` (`libGTASA.so`, `libSCAnd.so`, `libOpenAL64.so`,
fastman92 libs ...) are Rockstar / third-party files and are not needed to compile; keep them out of a public repo.

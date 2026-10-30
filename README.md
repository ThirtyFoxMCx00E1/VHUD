# vhud-android

Builds the **V HUD** mod for Android (`libVHUD32.so` + `libVHUD64.so`) with the NDK in GitHub Actions and packages it
together with the assets and an install guide. `libAML.so` is **not** built or shipped by default: the HUD only needs the
one already inside your patched APK.

## What the workflow does (`.github/workflows/build.yml`)
Runs on push (when `libVHUD32.so`, `libVHUD64.so`, `prebuilt/**`, `vhud/**`, `assets/**`, `templates/**`, `deps/**` or
`scripts/**` change), on pull requests, manually and on releases.

1. Clones `v-hud` (for its `resources/`) and `Psdk-aml` from `ThirtyFoxMCx00E1`.
2. Installs NDK r24 and compiles VHUD for the ABIs that have **no** uploaded lib. If you commit `libVHUD32.so` and/or
   `libVHUD64.so` (anywhere in the repo; `prebuilt/` is the intended place) that ABI is not recompiled; the file is checked
   (32-bit ARM vs arm64) and packaged.
3. Uploads the artifact **VHUD-Android**, laid out like the phone (tutorial in `mods/INSTALL.md`):
   - `mods/` - `libVHUD32.so`, `libVHUD64.so`, `INSTALL.md` -> `Android/data/<game package>/mods/`
   - `files/VHud/` - upstream `v-hud/resources` + your `assets/` -> `Android/data/<game package>/files/`
   - `BUILD_INFO.txt` - SHA-256 and whether each lib was uploaded or built

### Optional: tools build
Actions -> *Run workflow* -> tick **build_tools** to also compile ARMPatch, AML, SAUtils and the ImGui plugin into `tools/`.
This is not needed for the HUD. `libAML.so` is only packaged if it exports `earlyLaunchAMLCore` like the one in your APK;
SAUtils needs the private `GTASA_STRUCTS.h` / `GTASA_STRUCTS_210.h` (`deps/structs/` or an `SSH` secret).

## Layout
- `deps/` - your uploaded sources (AndroidModLoader headers are used to build the mod; the rest is for the tools build)
- `vhud/` - the Android port of V HUD (`src/`, `Android.mk`, `Application.mk`) - see `PORTING.md`
- `prebuilt/` - drop `libVHUD32.so` / `libVHUD64.so` here
- `assets/` - your own assets, copied to `files/VHud/`
- `templates/INSTALL.md` - the tutorial that ends up in `mods/`
- `scripts/` - `fetch-deps.sh`, `assemble.sh`, `build-vhud.sh`, `package.sh`, tool build helpers

## Not included on purpose
Game binaries (`libGTASA.so`, `libSCAnd.so`, `libOpenAL64.so`, fastman92 libs ...) are Rockstar / third-party files and are
not needed to compile; keep them out of a public repo.

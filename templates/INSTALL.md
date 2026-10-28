# V HUD for Android - install guide

This package mirrors the folders on your phone:

```
mods/     ->  /storage/emulated/0/Android/data/<game package>/mods/
files/    ->  /storage/emulated/0/Android/data/<game package>/files/
loader/       only needed if your game does not already have AML (see step 4)
```

`<game package>` is the package name of your GTA SA install (for the Rockstar version it is usually
`com.rockstargames.gtasa`; a modded APK can use another name - check it in Settings > Apps).

## 1. Check your game's bitness
- **32-bit game** (armeabi-v7a) uses `libVHUD32.so`, `libSAUtils.so`, `libDearImGui.so`.
- **64-bit game** (arm64-v8a) uses `libVHUD64.so`, `libSAUtils64.so`. (`libDearImGui.so` is 32-bit only.)

Copy only the files for your game's bitness. A library of the wrong bitness cannot be loaded.

## 2. Copy the mod libraries (`mods/`)
Copy the `.so` files from this `mods/` folder into
`Android/data/<game package>/mods/` (create the folder if it does not exist).
This `INSTALL.md` may stay in that folder, AML ignores it.

## 3. Copy the assets (`files/`)
Copy the `VHud` folder from `files/` into `Android/data/<game package>/files/`, so you end up with
`Android/data/<game package>/files/VHud/...`.

## 4. AML loader (usually already done)
`libAML.so` (in `loader/<abi>/`) is the mod loader, not a mod. It lives inside the game's APK (`lib/<abi>/`) and is
started by the smali patch described in the AndroidModLoader README (`external/` folder). If your game already
runs AML mods, skip this step.

## Android 11+ (cannot open Android/data)
The stock Files app cannot open `Android/data`. Use a file manager that supports it, or copy with adb from a PC:

```
adb push mods/. /sdcard/Android/data/<game package>/mods/
adb push files/. /sdcard/Android/data/<game package>/files/
```

## 5. Check that it loaded
Start the game and look at the log (`adb logcat`) for lines tagged `VHUD`, for example
`V HUD (32-bit) - libGTASA.so at 0x...`. No such line means the library was not loaded:
wrong bitness, wrong folder, or AML is not installed in the game.

## Notes
- `libVHUD32.so` / `libVHUD64.so` built from this repository's `vhud/src` are still the **scaffold** (they load and log,
  the HUD is not drawn yet). Upload your own full builds to `prebuilt/` and the workflow packages those instead.
- The upstream PC shaders (HLSL) are not shipped: Android needs GLSL ES versions of them.

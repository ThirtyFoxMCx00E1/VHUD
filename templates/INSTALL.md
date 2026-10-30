# V HUD for Android - install guide

This package mirrors the folders on your phone:

```
mods/     ->  /storage/emulated/0/Android/data/<game package>/mods/
files/    ->  /storage/emulated/0/Android/data/<game package>/files/
```

`<game package>` is the package name of your GTA SA install (for the Rockstar version it is usually
`com.rockstargames.gtasa`; a modded APK can use another name - check it in Settings > Apps).

## 1. Check your game's bitness
- **32-bit game** (armeabi-v7a) uses `libVHUD32.so`.
- **64-bit game** (arm64-v8a) uses `libVHUD64.so`.

Copy only the files for your game's bitness. A library of the wrong bitness cannot be loaded.

## 2. Copy the mod libraries (`mods/`)
Copy the `.so` files from this `mods/` folder into
`Android/data/<game package>/mods/` (create the folder if it does not exist).
This `INSTALL.md` may stay in that folder, AML ignores it.

## 3. Copy the assets (`files/`)
Copy the `VHud` folder from `files/` into `Android/data/<game package>/files/`, so you end up with
`Android/data/<game package>/files/VHud/...`.

## 4. libAML.so is not part of this package
V HUD is a normal AML mod: it only needs the `libAML.so` that is already inside your patched APK. Do **not** replace it.
(A `libAML.so` built from an older AML source lacks `earlyLaunchAMLCore`, which the APK calls at start-up; swapping it in
gives a black screen. If you did that, put the original back.)

## Android 11+ (cannot open Android/data)
The stock Files app cannot open `Android/data`. Use a file manager that supports it, or copy with adb from a PC:

```
adb push mods/. /sdcard/Android/data/<game package>/mods/
adb push files/. /sdcard/Android/data/<game package>/files/
```

## 5. Check that it loaded
Start the game. For about 20 seconds a small **green bar at the top centre** of the screen shows that the V HUD hook is
running. It also writes `Android/data/<game package>/files/VHud/vhud.log` (line 1 shows the version and which game
functions were found). No bar and no log means the library was not loaded: wrong bitness, wrong folder, or AML is not
installed in the game. Send me `vhud.log` after taking some damage and picking up armor.

## Notes
- Version 0.2 of `libVHUD32.so` / `libVHUD64.so` only proves the hooks and records data. It does **not** replace the
  game's HUD yet: that needs the real health/armor values, which the log will show (see `PORTING.md`).
  Upload your own full builds to `prebuilt/` and the workflow packages those instead.
- The upstream PC shaders (HLSL) are not shipped: Android needs GLSL ES versions of them.

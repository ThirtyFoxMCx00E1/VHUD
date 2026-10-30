# V HUD -> Android: port status

**Status: 0.2 - first hooks.** `libVHUD32.so` / `libVHUD64.so` hook `CHud::Draw`, draw a green indicator bar for ~20 s and log the
arguments of the player-info health/armor bar calls to `files/VHud/vhud.log`. The HUD itself is not replaced yet.

### Verified in your libGTASA.so (both ABIs, `nm -D`)
`CHud::Draw`, `CHud::DrawRadar`, `CHud::DrawVitalStats`, `CHud::DrawAreaName/HelpText/VehicleName/Subtitles/CrossHairs`,
`CWidgetPlayerInfo::Draw / RenderHealthBar(int,float) / RenderArmorBar(int,float) / RenderBreathBar / DrawWanted / DrawWeaponIcon / DrawAmmo`,
`CRadar::DrawRadarMap / DrawRadarMask`, `CSprite2d::DrawRect / Draw`, `CFont::PrintString / SetFontStyle / SetColor`,
`FindPlayerPed/Wanted/Coors`, `CWorld::Players`, `RsGlobal`. The player struct offsets (health, armor, money) are NOT exported
and still have to be confirmed: next step is to read them from `vhud.log` / the game binary.

## What upstream v-hud is
`gennariarmando/v-hud` (your fork: `ThirtyFoxMCx00E1/v-hud`) is a Windows plugin: Visual Studio 2019 + premake,
DirectX 9 with Pixel Shader 3.0, HLSL shaders compiled with `fxc.exe`, `bass.dll` for audio, loaded through an
ASI loader, written against DK22Pac's plugin-sdk, and only compatible with GTA SA 1.0 US.

## What has to be replaced for Android
| Upstream (PC) | Android replacement | Where to look |
|---|---|---|
| plugin-sdk (PC addresses) | Psdk-aml structures + per-architecture libGTASA offsets (32-bit and 64-bit differ) | `external/Psdk-aml`, `deps/SAUtils` |
| Direct3D 9 drawing + HLSL shaders | RenderWare-on-Android / OpenGL ES 2.0, shaders rewritten as GLSL ES | `deps/CLEO_ImGui/CLEO ImGui/jni/RW` and `backends/imgui_impl_renderware.cpp` show the RW access pattern |
| ASI loader / DLL hooks | AML mod (`MYMOD`, `ON_MOD_LOAD`) and `HOOK*` macros | `deps/AndroidModLoader/docs/DOCUMENTATION_EN.MD` |
| `bass.dll` audio | game audio (OpenAL is already in the game) or OpenSL ES | - |
| Mouse/keyboard, GInput | touch input already handled by the game | - |
| Windows file paths, `.dll` side files | files under the mod's Android data directory | - |

## Suggested order
1. Hook the game's HUD draw entry points and prove one element (e.g. money) draws on a 32-bit device.
2. Build a small 2D draw layer (textured quad, rect, text) on RenderWare for GLES; port the shader effects last.
3. Port element by element (radar, health/armor, wanted stars, weapon/ammo, clock, text boxes ...).
4. Repeat the offsets for arm64 and fill `libVHUD64.so`.
5. Port the config/XML parsing (pugixml is portable) and ship `resources/` next to the mod.

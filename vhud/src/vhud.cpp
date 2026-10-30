#include "vhud.h"
#include <mod/amlmod.h>
#include <mod/logger.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>

// ---------------------------------------------------------------------------
// V HUD 0.2 - first real hooks. Only symbols that exist in BOTH ABIs of the libGTASA.so
// you uploaded are used (checked with nm -D). No struct offsets are guessed.
//
//  * CHud::Draw                    -> hooked; the V HUD overlay is drawn right after the game HUD
//  * CWidgetPlayerInfo::RenderHealthBar / RenderArmorBar (int, float)
//                                  -> hooked only to LOG their arguments to files/VHud/vhud.log,
//                                     so the real health/armor source can be confirmed before bars are drawn
//  * CSprite2d::DrawRect           -> used for drawing (screen-pixel coordinates)
// ---------------------------------------------------------------------------
namespace
{
    struct CRect  { float left, bottom, right, top; };   // GTA layout: bottom has the bigger Y on screen
    struct CRGBA  { unsigned char r, g, b, a; };
    struct RsGlobalType { const char* appName; int maximumWidth; int maximumHeight; }; // same as the ImGui mod uses

    void      (*DrawRect)(const CRect&, const CRGBA&)  = nullptr;
    void      (*CHud_Draw)()                            = nullptr;
    uintptr_t (*RenderHealthBar)(void*, int, float)     = nullptr;
    uintptr_t (*RenderArmorBar)(void*, int, float)      = nullptr;
    RsGlobalType* RsGlobal = nullptr;

    char g_LogPath[512] = {0};
    int  g_LogLines = 0;
    const int kMaxLogLines = 150;

    unsigned g_Frames = 0;
    double   g_StartTime = -1.0;

    double NowSec()
    {
        timespec ts; clock_gettime(CLOCK_MONOTONIC, &ts);
        return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
    }

    void FileLog(const char* fmt, ...)
    {
        char buf[256];
        va_list va; va_start(va, fmt); vsnprintf(buf, sizeof(buf), fmt, va); va_end(va);
        logger->Info("%s", buf);
        if (!g_LogPath[0] || g_LogLines >= kMaxLogLines) return;
        ++g_LogLines;
        if (FILE* f = fopen(g_LogPath, "a")) { fputs(buf, f); fputc('\n', f); fclose(f); }
    }

    // Small green bar at the top centre for ~20 s after start: proof that the hook runs and DrawRect works.
    void DrawActiveIndicator()
    {
        if (g_StartTime < 0.0) g_StartTime = NowSec();
        if (g_Frames < 30 || NowSec() - g_StartTime > 20.0) return;
        const float W = (float)RsGlobal->maximumWidth, H = (float)RsGlobal->maximumHeight;
        if (W <= 0.0f || H <= 0.0f) return;
        const float w = W * 0.12f, h = H * 0.014f, x = (W - w) * 0.5f, y = H * 0.012f;
        const CRect frame = { x - 2.0f, y + h + 2.0f, x + w + 2.0f, y - 2.0f };
        const CRect fill  = { x,        y + h,        x + w,        y };
        const CRGBA dark = { 0, 0, 0, 170 }, green = { 61, 214, 107, 230 };
        DrawRect(frame, dark);
        DrawRect(fill, green);
    }

    void HookOf_CHud_Draw()
    {
        CHud_Draw();                       // the game's own HUD first
        if (++g_Frames == 1) FileLog("CHud::Draw hook is running (screen %dx%d)", RsGlobal->maximumWidth, RsGlobal->maximumHeight);
        DrawActiveIndicator();
    }

    // The return type is uintptr_t on purpose: whatever the original leaves in r0/x0 is passed on unchanged.
    uintptr_t HookOf_RenderHealthBar(void* self, int a, float b)
    {
        static int lastA = -12345; static float lastB = -12345.0f;
        if (a != lastA || b != lastB) { lastA = a; lastB = b; FileLog("RenderHealthBar(int=%d, float=%.3f)", a, b); }
        return RenderHealthBar(self, a, b);
    }
    uintptr_t HookOf_RenderArmorBar(void* self, int a, float b)
    {
        static int lastA = -12345; static float lastB = -12345.0f;
        if (a != lastA || b != lastB) { lastA = a; lastB = b; FileLog("RenderArmorBar(int=%d, float=%.3f)", a, b); }
        return RenderArmorBar(self, a, b);
    }
}

void VHud::Init()
{
    // files/VHud/vhud.log (same folder as the assets)
    const char* base = aml->GetAndroidDataPath();
    if (base && *base)
    {
        char dir[480];
        snprintf(dir, sizeof(dir), "%s/VHud", base);
        mkdir(dir, 0777);
        snprintf(g_LogPath, sizeof(g_LogPath), "%s/vhud.log", dir);
    }
    FileLog("---- V HUD 0.2.0 start (%s) ----", sizeof(void*) == 8 ? "64-bit" : "32-bit");

    RsGlobal = (RsGlobalType*)aml->GetSym(hGTASA, "RsGlobal");
    *(void**)&DrawRect        = (void*)aml->GetSym(hGTASA, "_ZN9CSprite2d8DrawRectERK5CRectRK5CRGBA");
    const uintptr_t hudDraw   = aml->GetSym(hGTASA, "_ZN4CHud4DrawEv");
    const uintptr_t healthBar = aml->GetSym(hGTASA, "_ZN17CWidgetPlayerInfo15RenderHealthBarEif");
    const uintptr_t armorBar  = aml->GetSym(hGTASA, "_ZN17CWidgetPlayerInfo14RenderArmorBarEif");
    FileLog("symbols: RsGlobal=%d DrawRect=%d CHud::Draw=%d RenderHealthBar=%d RenderArmorBar=%d",
            RsGlobal != nullptr, DrawRect != nullptr, hudDraw != 0, healthBar != 0, armorBar != 0);

    if (!RsGlobal || !DrawRect || !hudDraw)
    {
        FileLog("required symbols are missing - V HUD stays passive");
        return;
    }
    aml->Hook((void*)hudDraw, (void*)HookOf_CHud_Draw, (void**)&CHud_Draw);
    if (healthBar) aml->Hook((void*)healthBar, (void*)HookOf_RenderHealthBar, (void**)&RenderHealthBar);
    if (armorBar)  aml->Hook((void*)armorBar,  (void*)HookOf_RenderArmorBar,  (void**)&RenderArmorBar);
    FileLog("hooks installed");
}

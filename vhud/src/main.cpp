// V HUD - AML entry point (armeabi-v7a -> libVHUD32.so, arm64-v8a -> libVHUD64.so)
#include <mod/amlmod.h>
#include <mod/logger.h>
#include "vhud.h"

MYMOD(net.thirtyfox.vhud, V HUD, 0.1.0, ThirtyFox)

uintptr_t pGTASA = 0;
void*     hGTASA = nullptr;

ON_MOD_PRELOAD()
{
    logger->SetTag("VHUD");
}

ON_MOD_LOAD()
{
    logger->SetTag("VHUD");
    pGTASA = aml->GetLib("libGTASA.so");
    hGTASA = aml->GetLibHandle("libGTASA.so");
    if (!pGTASA || !hGTASA)
    {
        logger->Error("libGTASA.so was not found, V HUD will not start");
        return;
    }
    logger->Info("V HUD (%s) - libGTASA.so at 0x%lx", sizeof(void*) == 8 ? "64-bit" : "32-bit", (unsigned long)pGTASA);
    VHud::Init();
}

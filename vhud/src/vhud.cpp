#include "vhud.h"
#include <mod/amlmod.h>
#include <mod/logger.h>

// ---------------------------------------------------------------------------
// PORT STATUS: scaffold only. Nothing is hooked yet.
// See PORTING.md for what the upstream Windows plugin needs on Android.
// Add hooks here with DECL_HOOK*/HOOK* (see AML docs, section 8) and keep every
// libGTASA offset behind #ifdef __arm__ / #ifdef __aarch64__.
// ---------------------------------------------------------------------------
void VHud::Init()
{
    logger->Info("VHud::Init() - scaffold, no hooks installed");
}

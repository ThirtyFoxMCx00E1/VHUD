#pragma once
#include <stdint.h>

extern uintptr_t pGTASA;   // base of libGTASA.so
extern void*     hGTASA;   // dlopen handle of libGTASA.so

namespace VHud
{
    // Called once from OnModLoad(), after libGTASA.so is known to be loaded.
    void Init();
}

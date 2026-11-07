#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <unordered_map>
#include <shared_mutex>
#include <algorithm>

// rage::scrNativeCallContext layout
struct scrNativeCallContext
{
    void* m_pReturn;
    uint32_t m_nArgCount;
    void* m_pArgs;
    uint32_t m_nDataCount;
};

typedef void (*NativeHandler)(scrNativeCallContext* context);
typedef void (*RegisterNativeHandlerFn)(uint64_t hash, NativeHandler handler);
typedef NativeHandler (*GetNativeHandlerFn)(uint64_t hash);

static RegisterNativeHandlerFn g_registerNative = nullptr;
static GetNativeHandlerFn g_getNative = nullptr;

static NativeHandler g_origSetVehiclePlate = nullptr;
static NativeHandler g_origGetVehiclePlate = nullptr;
static NativeHandler g_origGetNumPlates = nullptr;

static std::unordered_map<int, int> g_vehiclePlateSlots;
static std::shared_mutex g_slotsMutex;

struct CustomPlateInfo
{
    int index = -1;
    std::string name;
    std::string txd;
    std::string txn;
    int baseColorIndex = 5;       // Default: 5 (Black text)
    uint32_t hexColor = 0xFF080808; // 32-bit ARGB
    float extentsX = 0.28f;       // Horizontal starting margin
    float extentsY = 0.355f;      // Vertical starting margin
    float extentsZ = 0.816f;      // Width span
    float extentsW = 0.92f;       // Height span
};

static std::unordered_map<int, CustomPlateInfo> g_customPlates;
static std::unordered_map<int, int> g_slotTextColors;
static std::shared_mutex g_platesMutex;

static void Log(const char* fmt, ...)
{
    char buf[1024];
    va_list va;
    va_start(va, fmt);
    vsnprintf(buf, sizeof(buf), fmt, va);
    va_end(va);
    OutputDebugStringA(buf);

    FILE* f = fopen("CustomPlates.log", "a");
    if (f)
    {
        fprintf(f, "%s\n", buf);
        fclose(f);
    }
}

// Convert any 32-bit ARGB hex color to the best matching GTA V native plate font slot:
// 5  = Black       (0xFF080808) - North Yankton / Las Venturas
// 11 = White       (0xFFFFFFFF) - Panic / Pounders
// 1  = Yellow/Gold (0xFFE0AF1F) - SA Black & Yellow
// 0  = Blue        (0xFF14244B) - San Andreas Standard
// 6  = Red         (0xFFB81D1D) - eCola / Exempt
// 10 = Green       (0xFF22B14C) - Sprunk
// 9  = Pink/Orange (0xFFFF69B4) - LS Car Meet
static int HexColorToBestFontSlot(uint32_t argb)
{
    int r = (argb >> 16) & 0xFF;
    int g = (argb >> 8) & 0xFF;
    int b = argb & 0xFF;

    // Perceived luminance: standard CCIR 601 formula
    int lum = (r * 299 + g * 587 + b * 114) / 1000;

    // Very dark -> Black text
    if (lum < 75) return 5;

    // Very bright and low saturation -> White text
    int maxC = (std::max)(r, (std::max)(g, b));
    int minC = (std::min)(r, (std::min)(g, b));
    int sat = (maxC > 0) ? ((maxC - minC) * 255 / maxC) : 0;

    if (lum > 180 && sat < 60) return 11; // White font

    // Dominant Red
    if (r > 130 && g < 110 && b < 110) return 6; // Red font

    // Dominant Green
    if (g > 120 && r < 110 && b < 110) return 10; // Green font

    // Dominant Yellow / Gold
    if (r > 130 && g > 110 && b < 90) return 1; // Yellow font

    // Dominant Blue
    if (b > 120 && r < 110) return 0; // Blue font

    // Pink / Purple / Magenta / Orange
    if (r > 150 && b > 80 && g < 110) return 9; // Pink / Orange font

    // Fallbacks
    if (lum >= 128) return 11; // White
    return 5; // Black
}

static uint32_t ParseHexColorString(const char* str)
{
    if (!str || !*str) return 0xFF080808;

    // Named color shortcuts
    if (_stricmp(str, "black") == 0) return 0xFF080808;
    if (_stricmp(str, "white") == 0) return 0xFFFFFFFF;
    if (_stricmp(str, "yellow") == 0) return 0xFFE0AF1F;
    if (_stricmp(str, "gold") == 0) return 0xFFFFD700;
    if (_stricmp(str, "blue") == 0) return 0xFF14244B;
    if (_stricmp(str, "red") == 0) return 0xFFB81D1D;
    if (_stricmp(str, "green") == 0) return 0xFF22B14C;
    if (_stricmp(str, "pink") == 0) return 0xFFFF69B4;
    if (_stricmp(str, "orange") == 0) return 0xFFFFA500;

    // Strip leading '#', '0x', '0X'
    if (str[0] == '#') str++;
    else if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X')) str += 2;

    uint32_t val = static_cast<uint32_t>(strtoul(str, nullptr, 16));
    // If only 6 hex digits (RRGGBB), add full alpha 0xFF000000
    if ((val & 0xFF000000) == 0 && strlen(str) <= 6)
    {
        val |= 0xFF000000;
    }
    return val;
}

// Custom handler for SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX (0x9088EB5A43FFB0A1)
static void MySetVehicleNumberPlateTextIndex(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int vehHandle = static_cast<int>(args[0]);
    int plateIndex = static_cast<int>(args[1]);

    if (plateIndex < 13)
    {
        if (g_origSetVehiclePlate)
        {
            g_origSetVehiclePlate(ctx);
        }
        std::unique_lock<std::shared_mutex> lock(g_slotsMutex);
        g_vehiclePlateSlots[vehHandle] = plateIndex;
        return;
    }

    // Custom slot (>= 13):
    // 1. Look up the custom slot's registered font / text color index:
    int targetFontIndex = 5; // Default: Black text (Yankton style)
    {
        std::shared_lock<std::shared_mutex> lock(g_platesMutex);
        auto it = g_slotTextColors.find(plateIndex);
        if (it != g_slotTextColors.end())
        {
            targetFontIndex = it->second;
        }
        else
        {
            auto it2 = g_customPlates.find(plateIndex);
            if (it2 != g_customPlates.end())
            {
                targetFontIndex = it2->second.baseColorIndex;
            }
            else
            {
                targetFontIndex = (plateIndex - 13) % 5;
            }
        }
    }

    // Pass the target font/layout index to GTA V's native vehicle plate setter
    args[1] = static_cast<uint64_t>(targetFontIndex);
    if (g_origSetVehiclePlate)
    {
        g_origSetVehiclePlate(ctx);
    }
    args[1] = plateIndex;

    // 2. Track custom plate slot
    {
        std::unique_lock<std::shared_mutex> lock(g_slotsMutex);
        g_vehiclePlateSlots[vehHandle] = plateIndex;
    }

    Log("[js_InfinityPlates] Set vehicle %d to custom slot %d (font color index %d)", vehHandle, plateIndex, targetFontIndex);
}

// Custom handler for GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX (0xF11BC2DD9A3E7195)
static void MyGetVehicleNumberPlateTextIndex(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int vehHandle = static_cast<int>(args[0]);

    {
        std::shared_lock<std::shared_mutex> lock(g_slotsMutex);
        auto it = g_vehiclePlateSlots.find(vehHandle);
        if (it != g_vehiclePlateSlots.end() && it->second >= 13)
        {
            *reinterpret_cast<int*>(ctx->m_pReturn) = it->second;
            return;
        }
    }

    if (g_origGetVehiclePlate)
    {
        g_origGetVehiclePlate(ctx);
    }
    else
    {
        *reinterpret_cast<int*>(ctx->m_pReturn) = 0;
    }
}

// Custom handler for GET_NUMBER_OF_VEHICLE_NUMBER_PLATES (0x4C4D6B2644F458CB)
static void MyGetNumberOfVehicleNumberPlates(scrNativeCallContext* ctx)
{
    int baseCount = 6;
    if (g_origGetNumPlates)
    {
        g_origGetNumPlates(ctx);
        baseCount = *reinterpret_cast<int*>(ctx->m_pReturn);
        if (baseCount <= 0 || baseCount > 100)
        {
            baseCount = 6;
        }
    }

    int customCount = 0;
    {
        std::shared_lock<std::shared_mutex> lock(g_platesMutex);
        customCount = static_cast<int>(g_customPlates.size());
    }

    if (customCount < 2)
    {
        customCount = 2; // slots 13 and 14
    }

    *reinterpret_cast<int*>(ctx->m_pReturn) = baseCount + customCount;
}

// Helper: Register or update custom plate entry
static void InternalRegisterPlate(int index, const char* name, const char* txd, const char* txn, int colorIndex, uint32_t hexColor, float x, float y, float z, float w)
{
    std::unique_lock<std::shared_mutex> lock(g_platesMutex);
    CustomPlateInfo& info = g_customPlates[index];
    info.index = index;
    if (name) info.name = name;
    if (txd) info.txd = txd;
    if (txn) info.txn = txn;
    info.baseColorIndex = colorIndex;
    info.hexColor = hexColor;
    info.extentsX = x;
    info.extentsY = y;
    info.extentsZ = z;
    info.extentsW = w;
    g_slotTextColors[index] = colorIndex;

    Log("[js_InfinityPlates] Registered slot %d ('%s') -> %s/%s [Hex=0x%08X FontSlot=%d Extents=(%.3f, %.3f, %.3f, %.3f)]",
        index, name ? name : "", txd ? txd : "", txn ? txn : "", hexColor, colorIndex, x, y, z, w);
}

// Custom native: REGISTER_CUSTOM_PLATE (0xA1B2C3D400000001)
// Args: (int slot, const char* name, const char* txd, const char* txn)
static void MyRegisterCustomPlate(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int index = static_cast<int>(args[0]);
    const char* name = reinterpret_cast<const char*>(args[1]);
    const char* txd = reinterpret_cast<const char*>(args[2]);
    const char* txn = reinterpret_cast<const char*>(args[3]);

    if (index >= 13)
    {
        InternalRegisterPlate(index, name, txd, txn, 5, 0xFF080808, 0.28f, 0.355f, 0.816f, 0.92f);
    }

    *reinterpret_cast<int*>(ctx->m_pReturn) = index;
}

// Custom native: SET_CUSTOM_PLATE_TEXT_COLOR (0xA1B2C3D400000002)
// Args: (int slot, int colorIndex)
static void MySetCustomPlateTextColor(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int slot = static_cast<int>(args[0]);
    int colorIndex = static_cast<int>(args[1]);

    if (slot >= 13)
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_slotTextColors[slot] = colorIndex;
        auto it = g_customPlates.find(slot);
        if (it != g_customPlates.end())
        {
            it->second.baseColorIndex = colorIndex;
        }
        Log("[js_InfinityPlates] Assigned font slot index %d to custom slot %d", colorIndex, slot);
    }

    *reinterpret_cast<BOOL*>(ctx->m_pReturn) = TRUE;
}

// Custom native: SET_CUSTOM_PLATE_HEX_COLOR (0xA1B2C3D400000005)
// Args: (int slot, const char* hexColorString OR uint32_t argbHex)
// Examples:
//   Citizen.InvokeNative(0xA1B2C3D400000005, 13, "#FFD700") -- Gold/Yellow
//   Citizen.InvokeNative(0xA1B2C3D400000005, 13, "white")
//   Citizen.InvokeNative(0xA1B2C3D400000005, 13, 0xFFFFFFFF)
static void MySetCustomPlateHexColor(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int slot = static_cast<int>(args[0]);
    uint64_t rawVal = args[1];

    uint32_t hexColor = 0xFF080808;
    // Check if passed as string pointer or numeric integer
    if (rawVal > 0x100000000ULL || (rawVal < 0x100000000ULL && rawVal > 0x10000ULL && IsBadReadPtr(reinterpret_cast<void*>(rawVal), 1) == 0))
    {
        // Try parsing string
        const char* str = reinterpret_cast<const char*>(rawVal);
        hexColor = ParseHexColorString(str);
    }
    else
    {
        hexColor = static_cast<uint32_t>(rawVal);
        if ((hexColor & 0xFF000000) == 0) hexColor |= 0xFF000000;
    }

    int fontSlot = HexColorToBestFontSlot(hexColor);

    if (slot >= 13)
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_slotTextColors[slot] = fontSlot;
        CustomPlateInfo& info = g_customPlates[slot];
        info.index = slot;
        info.hexColor = hexColor;
        info.baseColorIndex = fontSlot;
        Log("[js_InfinityPlates] Slot %d Hex=0x%08X -> mapped to FontSlot %d", slot, hexColor, fontSlot);
    }

    *reinterpret_cast<int*>(ctx->m_pReturn) = fontSlot;
}

// Custom native: SET_CUSTOM_PLATE_EXTENTS (0xA1B2C3D400000006)
// Args: (int slot, float x, float y, float width, float height)
// Controls placement / bounding box of the plate text:
//   x: Horizontal starting offset / left margin (default: 0.28)
//   y: Vertical starting offset / top margin (default: 0.355)
//   width: Bounding box width (default: 0.816)
//   height: Bounding box height (default: 0.92)
static void MySetCustomPlateExtents(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int slot = static_cast<int>(args[0]);
    float x = *reinterpret_cast<float*>(&args[1]);
    float y = *reinterpret_cast<float*>(&args[2]);
    float z = *reinterpret_cast<float*>(&args[3]);
    float w = *reinterpret_cast<float*>(&args[4]);

    if (slot >= 13)
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        CustomPlateInfo& info = g_customPlates[slot];
        info.index = slot;
        info.extentsX = x;
        info.extentsY = y;
        info.extentsZ = z;
        info.extentsW = w;
        Log("[js_InfinityPlates] Slot %d Extents set to (X=%.3f, Y=%.3f, W=%.3f, H=%.3f)", slot, x, y, z, w);
    }

    *reinterpret_cast<BOOL*>(ctx->m_pReturn) = TRUE;
}

// Custom native: SET_CUSTOM_PLATE_PROPERTIES (0xA1B2C3D400000007)
// Args: (int slot, const char* hexColor, float x, float y, float width, float height)
static void MySetCustomPlateProperties(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int slot = static_cast<int>(args[0]);
    const char* hexStr = reinterpret_cast<const char*>(args[1]);
    float x = *reinterpret_cast<float*>(&args[2]);
    float y = *reinterpret_cast<float*>(&args[3]);
    float z = *reinterpret_cast<float*>(&args[4]);
    float w = *reinterpret_cast<float*>(&args[5]);

    uint32_t hexColor = ParseHexColorString(hexStr);
    int fontSlot = HexColorToBestFontSlot(hexColor);

    if (slot >= 13)
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_slotTextColors[slot] = fontSlot;
        CustomPlateInfo& info = g_customPlates[slot];
        info.index = slot;
        info.hexColor = hexColor;
        info.baseColorIndex = fontSlot;
        info.extentsX = x;
        info.extentsY = y;
        info.extentsZ = z;
        info.extentsW = w;
        Log("[js_InfinityPlates] Slot %d Properties: Hex=0x%08X (FontSlot %d) Extents=(%.3f, %.3f, %.3f, %.3f)",
            slot, hexColor, fontSlot, x, y, z, w);
    }

    *reinterpret_cast<int*>(ctx->m_pReturn) = fontSlot;
}

static DWORD WINAPI WorkerThread(LPVOID)
{
    Log("[js_InfinityPlates] Worker thread started. Waiting for FiveM scripting engine...");

    // Wait until rage-scripting-five.dll is loaded
    HMODULE hRage = NULL;
    for (int i = 0; i < 60; ++i)
    {
        hRage = GetModuleHandleW(L"rage-scripting-five.dll");
        if (hRage) break;
        Sleep(500);
    }

    if (!hRage)
    {
        Log("[js_InfinityPlates] ERROR: rage-scripting-five.dll not found after 30s!");
        return 1;
    }

    Log("[js_InfinityPlates] Found rage-scripting-five.dll at %p", hRage);

    // Wait for native tables to be initialized
    Sleep(2000);

    g_registerNative = reinterpret_cast<RegisterNativeHandlerFn>(
        GetProcAddress(hRage, "?RegisterNativeHandler@scrEngine@rage@@SAX_KP6AXPEAVscrNativeCallContext@2@@Z@Z")
    );

    g_getNative = reinterpret_cast<GetNativeHandlerFn>(
        GetProcAddress(hRage, "?GetNativeHandler@scrEngine@rage@@SAP6AXPEAVscrNativeCallContext@2@@Z_K@Z")
    );

    if (!g_registerNative || !g_getNative)
    {
        Log("[js_InfinityPlates] ERROR: Failed to resolve RegisterNativeHandler or GetNativeHandler!");
        return 2;
    }

    // Capture original native handlers
    g_origSetVehiclePlate = g_getNative(0x9088EB5A43FFB0A1);
    g_origGetVehiclePlate = g_getNative(0xF11BC2DD9A3E7195);
    g_origGetNumPlates = g_getNative(0x4C4D6B2644F458CB);

    Log("[js_InfinityPlates] Captured original natives: SET=%p, GET=%p, NUM=%p",
        g_origSetVehiclePlate, g_origGetVehiclePlate, g_origGetNumPlates);

    // Register our unclamped plate handlers
    g_registerNative(0x9088EB5A43FFB0A1, MySetVehicleNumberPlateTextIndex);
    g_registerNative(0xF11BC2DD9A3E7195, MyGetVehicleNumberPlateTextIndex);
    g_registerNative(0x4C4D6B2644F458CB, MyGetNumberOfVehicleNumberPlates);

    // Register custom helper natives
    g_registerNative(0xA1B2C3D400000001ULL, MyRegisterCustomPlate);
    g_registerNative(0xA1B2C3D400000002ULL, MySetCustomPlateTextColor);
    g_registerNative(0xA1B2C3D400000005ULL, MySetCustomPlateHexColor);
    g_registerNative(0xA1B2C3D400000006ULL, MySetCustomPlateExtents);
    g_registerNative(0xA1B2C3D400000007ULL, MySetCustomPlateProperties);

    // Pre-populate default custom slots 13 and 14
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_customPlates[13] = { 13, "yankton_custom", "custom_plates", "yankton_plate", 5, 0xFF080808, 0.28f, 0.355f, 0.816f, 0.92f };
        g_customPlates[14] = { 14, "epsilon_custom", "custom_plates", "epsilon_plate", 0, 0xFF14244B, 0.28f, 0.355f, 0.816f, 0.92f };
        g_slotTextColors[13] = 5;
        g_slotTextColors[14] = 0;
    }

    Log("[js_InfinityPlates] Custom plate unclamping, hex color & text placement hooks active!");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID)
{
    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        DisableThreadLibraryCalls(hinstDLL);
        CreateThread(NULL, 0, WorkerThread, NULL, 0, NULL);
    }
    return TRUE;
}

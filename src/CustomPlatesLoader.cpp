#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <string>
#include <unordered_map>
#include <shared_mutex>

#pragma comment(lib, "user32.lib")

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

static char g_logPath[MAX_PATH] = { 0 };

static void InitLogPath(HMODULE hMod)
{
    char modPath[MAX_PATH] = { 0 };
    if (GetModuleFileNameA(hMod, modPath, MAX_PATH))
    {
        char* slash = strrchr(modPath, '\\');
        if (slash)
        {
            *(slash + 1) = '\0';
            strcpy_s(g_logPath, modPath);
            strcat_s(g_logPath, "CustomPlates.log");
        }
    }
}

static void Log(const char* fmt, ...)
{
    char buf[1024];
    va_list va;
    va_start(va, fmt);
    vsnprintf(buf, sizeof(buf), fmt, va);
    va_end(va);
    OutputDebugStringA(buf);

    if (g_logPath[0] != '\0')
    {
        FILE* f = fopen(g_logPath, "a");
        if (f)
        {
            fprintf(f, "%s\n", buf);
            fclose(f);
        }
    }
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
    // Map custom slot to an internal base index (0-4) so different custom plates can render distinct textures
    int baseIndex = (plateIndex - 13) % 5;
    args[1] = static_cast<uint64_t>(baseIndex);
    if (g_origSetVehiclePlate)
    {
        g_origSetVehiclePlate(ctx);
    }
    args[1] = static_cast<uint64_t>(plateIndex);

    // Track custom plate slot
    {
        std::unique_lock<std::shared_mutex> lock(g_slotsMutex);
        g_vehiclePlateSlots[vehHandle] = plateIndex;
    }

    Log("[js_InfinityPlates] Set vehicle %d to custom slot %d (baseIndex %d)", vehHandle, plateIndex, baseIndex);
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

    // Report expanded count to avoid scripts clamping to 6
    *reinterpret_cast<int*>(ctx->m_pReturn) = baseCount + 200;
}

static DWORD WINAPI WorkerThread(LPVOID)
{
    Log("[js_InfinityPlates] Worker thread started. Waiting for GTA V game window...");

    // Wait until GTA V game window is created (means all pre-gameload components, DirectX and adhesive have initialized)
    for (int i = 0; i < 120; ++i)
    {
        HWND hwnd = FindWindowA("grcWindow", NULL);
        if (hwnd)
        {
            Log("[js_InfinityPlates] Found GTA V grcWindow (%p) at iteration %d", hwnd, i);
            break;
        }
        Sleep(500);
    }

    // Additional settle delay after window creation
    Sleep(2000);

    // Wait until rage-scripting-five.dll is loaded
    HMODULE hRage = GetModuleHandleW(L"rage-scripting-five.dll");
    for (int i = 0; i < 30 && !hRage; ++i)
    {
        Sleep(500);
        hRage = GetModuleHandleW(L"rage-scripting-five.dll");
    }

    if (!hRage)
    {
        Log("[js_InfinityPlates] ERROR: rage-scripting-five.dll not found!");
        return 1;
    }

    Log("[js_InfinityPlates] Found rage-scripting-five.dll at %p", hRage);

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

    // Register our unclamped plate handlers ONLY for genuine GTA V natives
    g_registerNative(0x9088EB5A43FFB0A1, MySetVehicleNumberPlateTextIndex);
    g_registerNative(0xF11BC2DD9A3E7195, MyGetVehicleNumberPlateTextIndex);
    g_registerNative(0x4C4D6B2644F458CB, MyGetNumberOfVehicleNumberPlates);

    Log("[js_InfinityPlates] Custom license plate unclamping hooks active and safe!");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID)
{
    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        DisableThreadLibraryCalls(hinstDLL);
        InitLogPath(hinstDLL);
        Log("[js_InfinityPlates] CustomPlates.asi DLL_PROCESS_ATTACH (PID %lu)", GetCurrentProcessId());
        CreateThread(NULL, 0, WorkerThread, NULL, 0, NULL);
    }
    return TRUE;
}

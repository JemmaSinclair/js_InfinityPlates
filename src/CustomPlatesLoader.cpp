#include <windows.h>
#include <stdio.h>
#include <stdint.h>
#include <string>
#include <unordered_map>
#include <shared_mutex>

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
    int index;
    std::string name;
    std::string txd;
    std::string txn;
};

static std::unordered_map<int, CustomPlateInfo> g_customPlates;
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
    // 1. Map custom slot to an internal base index (0-4) so different custom plates can render distinct textures
    int baseIndex = (plateIndex - 13) % 5;
    args[1] = static_cast<uint64_t>(baseIndex);
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

    Log("[CustomPlates] Set vehicle %d to custom plate slot %d (baseIndex %d)", vehHandle, plateIndex, baseIndex);
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

// Custom helper native: REGISTER_CUSTOM_PLATE (0xA1B2C3D400000001)
static void MyRegisterCustomPlate(scrNativeCallContext* ctx)
{
    uint64_t* args = reinterpret_cast<uint64_t*>(ctx->m_pArgs);
    int index = static_cast<int>(args[0]);
    const char* name = reinterpret_cast<const char*>(args[1]);
    const char* txd = reinterpret_cast<const char*>(args[2]);
    const char* txn = reinterpret_cast<const char*>(args[3]);

    if (index >= 13 && name && txd && txn)
    {
        CustomPlateInfo info;
        info.index = index;
        info.name = name;
        info.txd = txd;
        info.txn = txn;

        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_customPlates[index] = info;
        Log("[CustomPlates] Registered custom plate slot %d ('%s') -> %s/%s", index, name, txd, txn);
    }

    *reinterpret_cast<int*>(ctx->m_pReturn) = index;
}

static DWORD WINAPI WorkerThread(LPVOID)
{
    Log("[CustomPlates] Worker thread started. Waiting for FiveM scripting engine...");

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
        Log("[CustomPlates] ERROR: rage-scripting-five.dll not found after 30s!");
        return 1;
    }

    Log("[CustomPlates] Found rage-scripting-five.dll at %p", hRage);

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
        Log("[CustomPlates] ERROR: Failed to resolve RegisterNativeHandler or GetNativeHandler!");
        return 2;
    }

    // Capture original native handlers
    g_origSetVehiclePlate = g_getNative(0x9088EB5A43FFB0A1);
    g_origGetVehiclePlate = g_getNative(0xF11BC2DD9A3E7195);
    g_origGetNumPlates = g_getNative(0x4C4D6B2644F458CB);

    Log("[CustomPlates] Captured original natives: SET=%p, GET=%p, NUM=%p",
        g_origSetVehiclePlate, g_origGetVehiclePlate, g_origGetNumPlates);

    // Register our unclamped plate handlers
    g_registerNative(0x9088EB5A43FFB0A1, MySetVehicleNumberPlateTextIndex);
    g_registerNative(0xF11BC2DD9A3E7195, MyGetVehicleNumberPlateTextIndex);
    g_registerNative(0x4C4D6B2644F458CB, MyGetNumberOfVehicleNumberPlates);

    // Register custom helper native (0xA1B2C3D400000001)
    g_registerNative(0xA1B2C3D400000001ULL, MyRegisterCustomPlate);

    // Pre-populate default custom slots 13 and 14
    {
        std::unique_lock<std::shared_mutex> lock(g_platesMutex);
        g_customPlates[13] = { 13, "yankton_custom", "custom_plates", "yankton_plate" };
        g_customPlates[14] = { 14, "epsilon_custom", "custom_plates", "epsilon_plate" };
    }

    Log("[CustomPlates] Custom license plate unclamping hooks active!");
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

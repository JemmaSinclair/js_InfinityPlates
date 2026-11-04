#include <windows.h>
#include <stdio.h>

struct Component {
    virtual bool Initialize() = 0;
    virtual bool DoGameLoad(void* module) = 0;
    virtual bool Shutdown() = 0;
};

typedef Component* (*CreateComponentFn)();

static HMODULE g_hPluginModule = NULL;
static wchar_t g_logPath[MAX_PATH] = L"";

static void Log(const char* fmt, ...)
{
    char buf[1024];
    va_list va;
    va_start(va, fmt);
    vsnprintf(buf, sizeof(buf), fmt, va);
    va_end(va);
    OutputDebugStringA(buf);

    if (g_logPath[0] != L'\0')
    {
        FILE* f = _wfopen(g_logPath, L"a");
        if (f)
        {
            fprintf(f, "%s\n", buf);
            fclose(f);
        }
    }
}

static DWORD WINAPI InitThread(LPVOID lpParam)
{
    Log("[CustomPlatesLoader] Background init thread active.");

    // Small delay to allow main process initialization
    Sleep(200);

    wchar_t asiPath[MAX_PATH] = { 0 };
    if (g_hPluginModule)
    {
        GetModuleFileNameW(g_hPluginModule, asiPath, MAX_PATH);
    }

    Log("[CustomPlatesLoader] ASI Module path: %ls", asiPath);

    HMODULE hCustom = NULL;
    wchar_t dllPath[MAX_PATH] = { 0 };

    // Candidate 1: Same directory as CustomPlates.asi (e.g. FiveM.app\plugins\extra-natives-custom.dll)
    if (asiPath[0] != L'\0')
    {
        wcscpy_s(dllPath, asiPath);
        wchar_t* slash = wcsrchr(dllPath, L'\\');
        if (slash)
        {
            *(slash + 1) = L'\0';
            wcscat_s(dllPath, L"extra-natives-custom.dll");
            Log("[CustomPlatesLoader] Probing Candidate 1: %ls", dllPath);
            hCustom = LoadLibraryW(dllPath);
        }
    }

    // Candidate 2: Parent directory (e.g. FiveM.app\extra-natives-custom.dll)
    if (!hCustom && asiPath[0] != L'\0')
    {
        wcscpy_s(dllPath, asiPath);
        wchar_t* slash = wcsrchr(dllPath, L'\\');
        if (slash)
        {
            *slash = L'\0'; // strip filename
            wchar_t* parentSlash = wcsrchr(dllPath, L'\\');
            if (parentSlash)
            {
                *(parentSlash + 1) = L'\0';
                wcscat_s(dllPath, L"extra-natives-custom.dll");
                Log("[CustomPlatesLoader] Probing Candidate 2: %ls", dllPath);
                hCustom = LoadLibraryW(dllPath);
            }
        }
    }

    // Candidate 3: Standard DLL search
    if (!hCustom)
    {
        Log("[CustomPlatesLoader] Probing Candidate 3: extra-natives-custom.dll via standard PATH");
        hCustom = LoadLibraryW(L"extra-natives-custom.dll");
    }

    if (!hCustom)
    {
        DWORD err = GetLastError();
        Log("[CustomPlatesLoader] ERROR: Failed to load extra-natives-custom.dll (GetLastError = %lu)", err);
        return 1;
    }

    Log("[CustomPlatesLoader] Successfully loaded extra-natives-custom.dll (Base = %p)", hCustom);

    auto createComponent = (CreateComponentFn)GetProcAddress(hCustom, "CreateComponent");
    if (!createComponent)
    {
        Log("[CustomPlatesLoader] ERROR: CreateComponent export not found in extra-natives-custom.dll!");
        return 2;
    }

    Component* comp = createComponent();
    if (!comp)
    {
        Log("[CustomPlatesLoader] ERROR: CreateComponent returned nullptr!");
        return 3;
    }

    Log("[CustomPlatesLoader] Calling Component::Initialize()...");
    bool initRes = comp->Initialize();
    Log("[CustomPlatesLoader] Component::Initialize() returned %s", initRes ? "TRUE" : "FALSE");

    Log("[CustomPlatesLoader] Calling Component::DoGameLoad()...");
    bool loadRes = comp->DoGameLoad(GetModuleHandle(NULL));
    Log("[CustomPlatesLoader] Component::DoGameLoad() returned %s", loadRes ? "TRUE" : "FALSE");

    Log("[CustomPlatesLoader] Custom plates expansion successfully hooked into FiveM!");
    return 0;
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    if (fdwReason == DLL_PROCESS_ATTACH)
    {
        DisableThreadLibraryCalls(hinstDLL);
        g_hPluginModule = hinstDLL;

        // Set log file location adjacent to CustomPlates.asi
        wchar_t asiPath[MAX_PATH] = { 0 };
        GetModuleFileNameW(hinstDLL, asiPath, MAX_PATH);
        wchar_t* slash = wcsrchr(asiPath, L'\\');
        if (slash)
        {
            *(slash + 1) = L'\0';
            wcscpy_s(g_logPath, asiPath);
            wcscat_s(g_logPath, L"custom_plates_loader.log");
        }

        Log("[CustomPlatesLoader] CustomPlates.asi attached (PID %lu)", GetCurrentProcessId());
        CreateThread(NULL, 0, InitThread, NULL, 0, NULL);
    }
    return TRUE;
}

# FiveM Vehicle License Plate Limit Expander (Slots 13+)

An additive vehicle license plate expansion for **FiveM** that breaks past Grand Theft Auto V's hardcoded plate index limit (0–12) to support an arbitrary number of custom plate slots ($\ge 13$) without overwriting or interfering with vanilla plates (0–12).

---

## Features

- **Arbitrary Plate Slots ($\ge 13$):** Expands plate indices past slot 12 additively; vanilla slots 0–5 (Blue on White, Yellow on Black, Yellow on Blue, Blue on White 2, North Yankton, Epsilon) and 6–12 remain 100% intact.
- **Native Unclamping:** Intercepts `SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0x9088EB5A43FFB0A1`), `GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0xF11BC2DD9A3E7195`), and `GET_NUMBER_OF_VEHICLE_NUMBER_PLATES` (`0x4C4D6B2644F458CB`) so custom indices are not clamped to 0 by the GTA V engine.
- **Shader Texture Replacement:** Automatically intercepts vehicle shader rendering (`CCustomShaderEffectVehicle::setDefaultPlateBack`) to bind custom diffuse and normal textures dynamically for custom slots.
- **Declarative XML Support:** Define plates declaratively in resource XML (`plates.meta`) via `vehicle_plate_file 'plates.meta'`.
- **Dynamic Script Registration:** Register custom plate styles on the fly via client-side Lua/JS/C# exports and natives.
- **Auto-Updater Safe:** Packaged as an ASI plugin in `FiveM.app/plugins/` alongside a dedicated component DLL (`extra-natives-custom.dll`), ensuring the production FiveM CDN bootstrapper never overwrites or reverts it on startup.

---

## Repository Layout

```text
License Plate Limit Increase/
├── bin/
│   ├── CustomPlates.asi            # FiveM client plugin for plugins/ folder
│   └── extra-natives-custom.dll    # Compiled native hook & registry engine
├── src/
│   ├── CustomPlatesLoader.cpp      # ASI loader entry point & thread initialiser
│   ├── CustomPlates.rc             # Multi-build resource definition (FX_ASI_BUILD)
│   └── build.bat                   # Standalone MSVC build script
├── core_patches/
│   ├── CustomPlateRegistry.h       # C++ Registry header
│   ├── CustomPlateRegistry.cpp     # C++ XML parser & registration engine
│   └── VehicleNumberPlateNatives.cpp # C++ Scripthook/rage hooks & native overrides
├── sample_resource/
│   └── custom_plates_test/         # Ready-to-use FiveM server resource
│       ├── fxmanifest.lua
│       ├── plates.meta             # Slot definitions (Slot 13: Yankton, Slot 14: Epsilon)
│       ├── client.lua              # Commands (/plate, /testplates)
│       └── stream/
│           └── custom_plates.ytd   # Streamed texture dictionary with plates & normals
├── build.bat                       # Root one-click build script
├── .gitignore
├── LICENSE
└── README.md
```

---

## Client Installation

1. Navigate to your FiveM application directory (`FiveM.app/`):
   - Typically: `%localappdata%\FiveM\FiveM.app\`
2. Open the `plugins` folder inside `FiveM.app/`:
   ```text
   FiveM.app/plugins/
   ```
3. Copy **both** files from `bin/` into `FiveM.app/plugins/`:
   - `CustomPlates.asi`
   - `extra-natives-custom.dll`
4. Launch FiveM normally. Both files sit side-by-side in `plugins/` and are never touched by the auto-updater.

---

## Server Setup & Testing

1. Copy the `sample_resource/custom_plates_test` folder into your server's `resources/` directory.
2. In your `server.cfg`, add:
   ```cfg
   ensure custom_plates_test
   ```
3. Start or restart your server.
4. Connect to the server, get into any vehicle, and test:
   - `/plate 13` — Applies custom slot 13 (North Yankton style).
   - `/plate 14` — Applies custom slot 14 (Epsilon style).
   - `/testplates` — Runs the automated test suite verifying slot count, native reads/writes, and runtime registration.

---

## Defining Plates in `plates.meta`

In any FiveM resource, add a `plates.meta` file:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CVehiclePlateDataStore>
    <plates>
        <!-- Custom slot 13 -->
        <Item>
            <name>yankton_custom</name>
            <index>13</index>
            <diffuseDict>custom_plates</diffuseDict>
            <diffuseTex>yankton_plate</diffuseTex>
            <normalDict>custom_plates</normalDict>
            <normalTex>yankton_plate_n</normalTex>
            <pattern>11AAA111</pattern>
        </Item>

        <!-- Custom slot 14 -->
        <Item>
            <name>epsilon_custom</name>
            <index>14</index>
            <diffuseDict>custom_plates</diffuseDict>
            <diffuseTex>epsilon_plate</diffuseTex>
            <normalDict>custom_plates</normalDict>
            <normalTex>epsilon_plate_n</normalTex>
            <pattern>KIFFLOM1</pattern>
        </Item>
    </plates>
</CVehiclePlateDataStore>
```

In your `fxmanifest.lua`:

```lua
fx_version 'cerulean'
game 'gta5'

files {
    'plates.meta'
}

vehicle_plate_file 'plates.meta'
```

Place your texture dictionary (`custom_plates.ytd`) in the resource's `stream/` folder containing your diffuse (`.png` / `.dds`) and normal map (`_n`) plate textures.

---

## Dynamic Script API (Lua)

### 1. Register a plate style at runtime:
```lua
local slotIndex = AddVehicleNumberPlateStyle(
    "california_exempt",  -- unique name
    "custom_plates",      -- texture dictionary (.ytd)
    "ca_exempt",          -- diffuse texture name
    "custom_plates",      -- normal map dictionary
    "ca_exempt_n",        -- normal map texture name
    "EXEMPT11"            -- character generation pattern
)
-- slotIndex will be the next available slot (>= 13)
```

### 2. Lookup slot index by name:
```lua
local slot = GetVehicleNumberPlateIndexByName("yankton_custom")
if slot ~= -1 then
    SetVehicleNumberPlateTextIndex(vehicle, slot)
end
```

### 3. Native Usage:
Standard natives work seamlessly with custom slots:
```lua
SetVehicleNumberPlateTextIndex(vehicle, 13)
local currentPlate = GetVehicleNumberPlateTextIndex(vehicle) -- returns 13
local totalPlates = GetNumberOfVehicleNumberPlates()         -- returns vanilla count + custom count
```

---

## Building from Source

### Prerequisites
- Visual Studio 2022 / 2026 with the C++ Desktop Development workload.
- Windows 10/11 SDK.

### Build
Run `build.bat` in the repository root or execute:
```cmd
cd src
call build.bat
```
The script automatically locates the MSVC tools via `vcvars64.bat`, compiles the resource script `CustomPlates.rc` with `rc.exe`, and builds `CustomPlates.asi` with `cl.exe`.

---

## License

MIT License. See [LICENSE](LICENSE) for details.


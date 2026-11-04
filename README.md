# js_InfinityPlates

An additive vehicle license plate expansion for **FiveM** that breaks past Grand Theft Auto V's hardcoded plate index limit (0–12) to support an arbitrary number of custom plate slots ($\ge 13$) without overwriting or interfering with vanilla plates (0–12).

---

## Features

- **Unlimited Plate Slots ($\ge 13$):** Expands plate indices past slot 12 additively; vanilla slots 0–5 (Blue on White, Yellow on Black, Yellow on Blue, Blue on White 2, North Yankton, Epsilon) and 6–12 remain 100% intact.
- **Native Unclamping:** Intercepts `SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0x9088EB5A43FFB0A1`), `GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0xF11BC2DD9A3E7195`), and `GET_NUMBER_OF_VEHICLE_NUMBER_PLATES` (`0x4C4D6B2644F458CB`) dynamically so custom indices are not clamped by the GTA V engine.
- **Multiplayer Network Synchronization:** Automatic OneSync replicated state bag synchronization (`Entity(veh).state.plateSlot`) ensuring all players with the plugin see custom plates on all vehicles in real-time.
- **Proximity & Late-Joiner Streaming Scope:** Nearby vehicles streaming into view automatically receive custom plate textures with zero desync or flickering.
- **Ambient Population Traffic Spawning:** Configurable percentage (e.g. 3%) of ambient world traffic and parked cars naturally spawn with weighted custom plates, fully synced across all players.
- **Auto-Updater Safe:** Packaged as a clean, standalone client plugin (`CustomPlates.asi`) in `FiveM.app/plugins/`, completely immune to FiveM auto-update wipes and LoaderLock deadlocks.
- **Collision-Free Slot Texture Mapping:** Custom plates map to dedicated base textures, allowing multiple vehicles with different custom plates to be parked side-by-side simultaneously.

---

## Repository Layout

```text
js_InfinityPlates/
├── bin/
│   └── CustomPlates.asi            # Pre-compiled standalone FiveM client plugin
├── src/
│   ├── CustomPlatesLoader.cpp      # Standalone native unclamp & registration engine
│   ├── CustomPlates.rc             # Multi-build resource definition (FX_ASI_BUILD)
│   └── build.bat                   # MSVC build script
├── core_patches/
│   ├── CustomPlateRegistry.h       # C++ Registry header
│   ├── CustomPlateRegistry.cpp     # C++ XML parser & registration engine
│   └── VehicleNumberPlateNatives.cpp # C++ Scripthook/rage hooks & native overrides
├── sample_resource/
│   └── js_InfinityPlates/          # Ready-to-use FiveM server resource
│       ├── fxmanifest.lua
│       ├── config.lua              # Configurable ambient traffic spawn rates & plate weights
│       ├── plates.meta             # Slot definitions (Slot 13: Yankton, Slot 14: Epsilon)
│       ├── client.lua              # Client sync, streaming scope monitor, commands (/plate, /testplates)
│       ├── server.lua              # OneSync state bag replication & ambient population distribution
│       ├── stream/
│       │   └── custom_plates.ytd   # Streamed texture dictionary with plates & normals
│       └── textures/               # Source PNG plate & normal textures
├── build.bat                       # Root one-click build script
├── .gitignore                      # Comprehensive git ignore rules
├── LICENSE                         # MIT License
└── README.md
```

---

## Downloads (Latest Release)

Grab the pre-packaged files directly from the [**Latest Release**](https://github.com/JemmaSinclair/js_InfinityPlates/releases/tag/latest):

- **[`CustomPlates.asi`](https://github.com/JemmaSinclair/js_InfinityPlates/releases/download/latest/CustomPlates.asi)** — Standalone FiveM client plugin.
- **[`Server.Resource.zip`](https://github.com/JemmaSinclair/js_InfinityPlates/releases/download/latest/Server.Resource.zip)** — Ready-to-use `js_InfinityPlates` FiveM server resource archive.

---

## Client Installation

1. Download **[`CustomPlates.asi`](https://github.com/JemmaSinclair/js_InfinityPlates/releases/download/latest/CustomPlates.asi)** from the [Latest Release](https://github.com/JemmaSinclair/js_InfinityPlates/releases/tag/latest) (or copy it from `bin/CustomPlates.asi` in this repository).
2. Navigate to your FiveM application directory (`FiveM.app/`):
   - Typically: `%localappdata%\FiveM\FiveM.app\`
3. Open the `plugins` folder inside `FiveM.app/`:
   ```text
   FiveM.app/plugins/
   ```
   *(If the `plugins` folder does not exist, create it).*
4. Place **`CustomPlates.asi`** inside `FiveM.app/plugins/`. That's it!
5. Launch FiveM normally. Because it lives in `plugins/`, FiveM's auto-updater will never overwrite it.

---

## Server Setup & Testing

1. Download **[`Server.Resource.zip`](https://github.com/JemmaSinclair/js_InfinityPlates/releases/download/latest/Server.Resource.zip)** from the [Latest Release](https://github.com/JemmaSinclair/js_InfinityPlates/releases/tag/latest) and extract the `js_InfinityPlates` folder into your server's `resources/` directory (or copy `sample_resource/js_InfinityPlates` from this repository).
2. In your `server.cfg`, add:
   ```cfg
   ensure js_InfinityPlates
   ```
3. Start or restart your server.
4. Connect to the server, get into any vehicle, and test:
   - `/plate 13` — Applies custom slot 13 (North Yankton style).
   - `/plate 14` — Applies custom slot 14 (Epsilon style).
   - `/plate 0` — Returns to vanilla San Andreas plate.
   - `/testplates` — Runs the automated test suite verifying slot count, native reads/writes, and network synchronization.

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

Place your texture dictionary (`custom_plates.ytd`) in the resource's `stream/` folder containing your diffuse and normal map plate textures.

---

## Ambient Population & Traffic Spawning

Custom plates can naturally appear on a configurable percentage of ambient NPC traffic in the world (e.g. 3% of road traffic and parked cars):

- Configured directly in [`config.lua`](sample_resource/js_InfinityPlates/config.lua):
  ```lua
  Config.EnablePopulationPlates = true
  Config.CustomPlateChance = 3.0 -- 3% of normal population spawns with custom plates

  -- Weighted custom plate distribution
  Config.CustomPlates = {
      { slot = 13, name = "North Yankton", weight = 60 }, -- 60% of custom plates
      { slot = 14, name = "Epsilon",       weight = 40 }  -- 40% of custom plates
  }
  ```
- **Player-Safe:** Only targets ambient world traffic (`POPTYPE_RANDOM_AMBIENT`, `POPTYPE_RANDOM_PARKED`, etc.). Mission and player-owned vehicles (`POPTYPE_MISSION`) are excluded, protecting player garage cars from being altered.

---

## Public Script API & Exports

Other server and client resources (garages, dealerships, mechanic shops) can interact with custom plates:

```lua
-- Set plate slot (Client or Server)
exports['js_InfinityPlates']:SetVehiclePlateSlot(vehicle, 13)

-- Get plate slot (Client or Server)
local slot = exports['js_InfinityPlates']:GetVehiclePlateSlot(vehicle)
```

Standard natives work seamlessly with custom slots:
```lua
SetVehicleNumberPlateTextIndex(vehicle, 13)
local currentPlate = GetVehicleNumberPlateTextIndex(vehicle) -- returns 13
local totalPlates = GetNumberOfVehicleNumberPlates()         -- returns unclamped count
```

---

## Building from Source

### Prerequisites
- Visual Studio 2022 / 2026 with C++ Desktop Development.
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

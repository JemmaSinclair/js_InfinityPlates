# js_InfinityPlates

An additive vehicle license plate expansion for **FiveM** that breaks past Grand Theft Auto V's hardcoded plate index limit (0–12) to support an arbitrary number of custom plate slots ($\ge 13$) without overwriting or interfering with vanilla plates (0–12).

---

## Features

- **Unlimited Plate Slots ($\ge 13$):** Expands plate indices past slot 12 additively; vanilla slots 0–5 (Blue on White, Yellow on Black, Yellow on Blue, Blue on White 2, North Yankton, Epsilon) and 6–12 remain 100% intact.
- **Native Unclamping:** Intercepts `SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0x9088EB5A43FFB0A1`), `GET_VEHICLE_NUMBER_PLATE_TEXT_INDEX` (`0xF11BC2DD9A3E7195`), and `GET_NUMBER_OF_VEHICLE_NUMBER_PLATES` (`0x4C4D6B2644F458CB`) dynamically so custom indices are not clamped by the GTA V engine.
- **Arbitrary Font Colors & Hex Support:** Intercepts plate font rendering and text coloring via native `0xA1B2C3D400000005` (`SET_CUSTOM_PLATE_HEX_COLOR`) and `0xA1B2C3D400000002` supporting arbitrary hex color codes (e.g. `'#FFD700'`, `'#080808'`, `'#00FF66'`, `'#FFFFFF'`) or classic indices (`5`=Black, `11`=White, `1`=Yellow, `0`=Blue, `6`=Red, `10`=Green) natively in memory—completely eliminating the need for `carcols.ymt` or client `.rpf` mods!
- **Text Placement & Bounding Box Extents:** Native `0xA1B2C3D400000006` (`SET_CUSTOM_PLATE_EXTENTS`) enables defining custom plate text placement and bounding box coordinates (`x`, `y`, `width`, `height`) per-plate style directly from `config.lua` or dynamically via script exports.
- **Multiplayer Network Synchronization:** Automatic OneSync replicated state bag synchronization (`Entity(veh).state.plateSlot`) ensuring all players with the plugin see custom plates on all vehicles in real-time.
- **Proximity & Late-Joiner Streaming Scope:** Nearby vehicles streaming into view automatically receive custom plate textures with zero desync or flickering.
- **Multi-State & 135+ Custom Plate Catalog:** Pre-configured with 135 authentic custom plates spanning 21 US states (Oregon, California, New York, Florida, Texas, Louisiana, etc.), with authentic font colors, hex palettes, placement extents, and both **Real-world** and **GTA lore-friendly** variant support.
- **Server State Regionalization:** Set `Config.ServerState` (e.g. `'Oregon'`, `'Louisiana'`) to make ambient world traffic prioritize local state plates (e.g. 90% local traffic), with the remaining percentage drawn from out-of-state travelers.
- **Replace Vanilla Slots 0–12:** Optional toggle (`Config.ReplaceVanillaSlots = true`) automatically rebinds vanilla plate indices 0–12 to your primary server state's plates, ensuring any vehicle spawned with default GTA plate indices displays your regional plates natively without extra scripts.
- **Civilian vs. Government/Exempt Plates:** Government, State Trooper, Police, Sheriff, and Municipal plates are automatically weighted (`weight = 0`) to prevent ambient traffic from spawning with them, keeping them reserved for emergency vehicles, job scripts, and mechanics.
- **Flexible Base Plate Mapping:** Custom plates can be mapped directly to dedicated base textures in `vehshare` (e.g. `plate01`, `plate02`, `yankton_plate`, `plate_mod_01`, etc.) or auto-assigned collision-free.
- **Dynamic Slot Indexing & Rich Exports:** Slot numbers are generated dynamically at startup, and full query exports (`GetAllPlates`, `GetPlateNames`, `GetPlateBySlot`, `GetPlateByName`, `GetPlatesByState`, `GetServerState`, `SetServerState`) allow easy integration into custom garage and vehicle shop UIs.
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
│       ├── config.lua              # State Lore/Real toggles, ambient traffic spawn rates, font colors & extents
│       ├── plates.meta             # 135+ Custom slot definitions across 21 US states (Slots 13–147)
│       ├── client.lua              # Client sync, dynamic texture mapping, commands (/plate, /testplates)
│       ├── server.lua              # OneSync state bag replication & ambient population distribution
│       └── stream/
│           ├── custom_plates.ytd   # Sample plate texture dictionary (Slots 13 & 14)
│           └── (Your State .ytds)  # Server owners drop their own plate texture dictionaries here
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

> [!IMPORTANT]
> **Custom Plate Textures (`.ytd` files):**
> Due to redistribution and licensing restrictions on third-party texture packs, state-specific `.ytd` files (`oregon.ytd`, `california.ytd`, etc.) are **not** bundled in this repository.
> The complete 135+ plate catalog in [`config.lua`](sample_resource/js_InfinityPlates/config.lua) and [`plates.meta`](sample_resource/js_InfinityPlates/plates.meta) is provided as an out-of-the-box configuration template with authentic font colors, hex palettes, and extents. Server owners simply supply their own `.ytd` files in `stream/` matching the dictionary and texture names, or customize `Config.Plates` to match their own server's plate assets.

---

## Configuration & Ambient Traffic Spawning

Custom plates can naturally appear on a configurable percentage of ambient NPC traffic in the world:

- Configured directly in [`config.lua`](sample_resource/js_InfinityPlates/config.lua):
  ```lua
  -- Primary State your server is set in (e.g. 'Oregon', 'Louisiana', 'California', etc.)
  Config.ServerState = 'Oregon'

  -- Percentage of ambient traffic that receives plates from your primary Config.ServerState (e.g. 90 = 90% in-state traffic)
  -- The remaining percentage (e.g. 10%) will be chosen from any other states enabled in Config.EnabledStates (out-of-state travelers).
  Config.ServerStateRatio = 90.0

  -- Replace vanilla plate slots 0-12 with your ServerState's plates
  -- When true, slots 0-12 in vehshare are rebound to your primary state's plates so default spawned vehicles display regional plates!
  Config.ReplaceVanillaSlots = true

  -- Overall chance (0.0 to 100.0) that a normal population vehicle spawns with a custom plate
  Config.CustomPlateChance = 100.0

  -- Per-State Lore mode toggle (true = Lore equivalent texture dictionary, false = Real-world actual state dictionary)
  Config.StateLoreMode = {
      ['Oregon'] = false,     -- false: oregon.ytd, true: oregon_lore.ytd
      ['Louisiana'] = false,  -- false: louisiana.ytd, true: louisiana_lore.ytd
      ...
  }

  -- Per-State Ambient Enable toggle (Set true if traffic can spawn with plates from this state)
  Config.EnabledStates = {
      ['Oregon'] = true,
      ['Washington'] = true, -- Out-of-state travelers
      ...
  }
  ```

### Custom Plates Definition & Base Mapping

`Config.Plates` is grouped cleanly by **State**. You no longer have to type repetitive `state`, `realDict`, or `loreDict` keys—the resource infers them automatically while allowing optional overrides:

```lua
Config.Plates = {
    ['Oregon'] = {
        {
            name = 'Douglas Fir Tree Standard',
            tex = 'tree_standard',
            textColor = 0, -- Embossed Dark Blue
            pattern = '111AAA'
        },
        {
            name = 'Pacific Wonderland Centennial',
            tex = 'pacific_wonderland',
            textColor = '#FFD700', -- Gold / Yellow Hex
            fontExtents = { x = 0.28, y = 0.36, w = 0.82, h = 0.90 }, -- (x, y, width, height)
            pattern = '1A1111'
        },
        {
            name = 'Smokey Bear Keep Oregon Green',
            tex = 'smokey_bear',
            textColor = 0, -- Dark Navy Blue
            pattern = '11111'
        },
        {
            name = 'Oregon Coast Aquarium Puffin',
            tex = 'coastal_aquarium',
            textColor = 0, -- Dark Blue
            pattern = '11111'
        },
        {
            name = 'Publicly Owned Government',
            tex = 'publicly_owned',
            textColor = 0, -- Dark Blue
            weight = 0,
            pattern = '111111'
        }, -- weight = 0: Excludes from ambient civilian traffic
    },

    ['Louisiana'] = {
        { name = 'Pelican Standard', tex = 'pelican_standard', baseTex = 'plate01', pattern = 'AAA111' },
        { name = "Sportsman's Paradise (1994)", tex = 'sportsmans_1994', baseTex = 'plate02', pattern = 'AAA111' },
        { name = 'Commercial', tex = 'commercial', baseTex = 'plate_mod_01', pattern = 'A111111' },
        { name = 'Pelican Standard (Alt)', tex = 'pelican_alt', pattern = 'AAA111' },
        { name = 'Public Government', tex = 'public_government', textColor = 0, baseTex = 'plate05', weight = 0, pattern = '111111' },
        { name = 'State Police', tex = 'state_police', textColor = 6, baseTex = 'yankton_plate', weight = 0, pattern = 'A111' },
    },
    ...
}
```

- **`tex`:** (Required) Texture name inside the state's `.ytd`.
- **`name`:** (Required) Display name for commands, exports, and menus.
- **`baseTex`:** (Optional) Explicitly pin to a specific `vehshare` texture (`plate01`, `plate02`, `plate05`, `yankton_plate`, `plate_mod_01`). If omitted, collision-free base textures are assigned automatically.
- **`textColor`:** (Optional) Font color:
  - Any **Hex string** (e.g. `'#FFD700'`, `'#080808'`, `'#00FF66'`, `'#FFFFFF'`).
  - Common color names: `'white'`, `'black'`, `'gold'`, `'yellow'`, `'blue'`, `'red'`, `'green'`.
  - Classic Color Index: `5` = Black (default), `11` = White, `1` = Yellow, `0` = Blue, `6` = Red, `10` = Green.
- **`fontExtents`:** (Optional) Custom text placement coordinates and bounding box `{ x = 0.28, y = 0.36, w = 0.82, h = 0.90 }`:
  - `x`: Horizontal offset / left margin (default ~`0.28`)
  - `y`: Vertical offset / top margin (default ~`0.355`)
  - `w`: Text block width (default ~`0.816`)
  - `h`: Text block height (default ~`0.92`)
- **`weight = 0`:** Excludes police, state trooper, emergency, and government exempt plates from ambient civilian traffic so NPC cars never roll them.
- **`slot`:** (Optional) Pin a plate to a specific index number, or leave it omitted for dynamic automatic indexing.

---

## Public Script API & Exports

Other server and client resources (custom garages, dealerships, mechanic shops, radial menus, UI builders) can query plates and assign custom styles via exports on both **client** and **server**:

```lua
-- 1. Get the full list of all registered custom plates
-- Returns array of table entries with { slot, state, name, tex, textColor, pattern, weight, ... }
local allPlates = exports['js_InfinityPlates']:GetAllPlates()

-- 2. Get a key-value map of slot numbers to plate names: { [13] = "Beach Standard (2022)", ... }
local plateNames = exports['js_InfinityPlates']:GetPlateNames()

-- 3. Get plate details for a specific slot number (or nil if invalid)
local plate = exports['js_InfinityPlates']:GetPlateBySlot(13)

-- 4. Find plate by name (case-insensitive)
local plate = exports['js_InfinityPlates']:GetPlateByName('Douglas Fir Tree Standard')

-- 5. Get all plates belonging to a specific state (e.g. 'Oregon', 'California')
local oregonPlates = exports['js_InfinityPlates']:GetPlatesByState('Oregon')

-- 6. Get or set the font text color (Hex string or numeric index)
local textColor = exports['js_InfinityPlates']:GetCustomPlateTextColor(13)
exports['js_InfinityPlates']:SetCustomPlateHexColor(13, '#FFD700')     -- Set custom gold hex color
exports['js_InfinityPlates']:SetCustomPlateTextColor(13, 11)          -- Set classic white index

-- 7. Get or set text placement & bounding box extents
local extents = exports['js_InfinityPlates']:GetCustomPlateExtents(13) -- { x=0.28, y=0.36, w=0.82, h=0.90 }
exports['js_InfinityPlates']:SetCustomPlateExtents(13, 0.28, 0.36, 0.82, 0.90)

-- 8. Set both hex color and extents in a single call
exports['js_InfinityPlates']:SetCustomPlateProperties(13, '#FFD700', 0.28, 0.36, 0.82, 0.90)

-- 9. Get or set the active server state setting
local currentState = exports['js_InfinityPlates']:GetServerState() -- returns 'Oregon'
exports['js_InfinityPlates']:SetServerState('California')           -- sets new primary state

-- 10. Apply plate slot to a vehicle (Client or Server, synced via OneSync state bags)
exports['js_InfinityPlates']:SetVehiclePlateSlot(vehicle, 13)

-- 11. Get plate slot of a vehicle (Client or Server)
local slot = exports['js_InfinityPlates']:GetVehiclePlateSlot(vehicle)
```

Standard natives work seamlessly with custom slots:
```lua
SetVehicleNumberPlateTextIndex(vehicle, 13)
local currentPlate = GetVehicleNumberPlateTextIndex(vehicle) -- returns 13
local totalPlates = GetNumberOfVehicleNumberPlates()         -- returns unclamped count
```

---

## Client Plugin C++ Natives (`CustomPlates.asi`)

`CustomPlates.asi` registers custom natives dynamically that can be invoked via `Citizen.InvokeNative` from any client-side Lua or C# resource:

| Native Hash | Name | Parameters | Description |
|---|---|---|---|
| `0xA1B2C3D400000001` | `REGISTER_CUSTOM_PLATE_SLOT` | `(int slot)` | Registers a custom plate slot (>= 13) into the engine. |
| `0xA1B2C3D400000002` | `SET_CUSTOM_PLATE_TEXT_COLOR` | `(int slot, int colorIndex)` | Routes custom slot to a native font palette (`5`=Black, `11`=White, `1`=Yellow, `0`=Blue, `6`=Red, `10`=Green). |
| `0xA1B2C3D400000003` | `GET_CUSTOM_PLATE_TEXT_COLOR` | `(int slot)` | Returns registered font color index for slot. |
| `0xA1B2C3D400000004` | `IS_CUSTOM_PLATE_SLOT` | `(int slot)` | Checks if slot index is managed as a custom plate. |
| `0xA1B2C3D400000005` | `SET_CUSTOM_PLATE_HEX_COLOR` | `(int slot, const char* hexString)` | Applies arbitrary hex color (e.g. `'#FFD700'`, `'#080808'`) to slot. |
| `0xA1B2C3D400000006` | `SET_CUSTOM_PLATE_EXTENTS` | `(int slot, float x, float y, float width, float height)` | Controls text position and bounding box extents. |
| `0xA1B2C3D400000007` | `SET_CUSTOM_PLATE_PROPERTIES` | `(int slot, const char* hex, float x, float y, float w, float h)` | Sets hex color and placement in a single call. |

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

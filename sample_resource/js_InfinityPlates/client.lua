-- js_InfinityPlates / custom_plates_test: Client-Side Custom License Plate System & Sync
-- Supports dynamic slot indexing, real/lore switching, vanilla 0-12 replacement, and full public exports

local CustomPlateStyles = {}
local PlatesBySlot = {}
local PlatesByName = {}
local PlatesByState = {}
local AllPlatesList = {}

-- GTA V Vanilla vehshare plate texture names mapped to indices 0 through 12
local VanillaPlateTextures = {
    [0] = { diffuse = "plate01", normal = "plate01_n" }, -- Blue on White
    [1] = { diffuse = "plate02", normal = "plate02_n" }, -- Yellow on Black
    [2] = { diffuse = "plate03", normal = "plate03_n" }, -- Yellow on Blue
    [3] = { diffuse = "plate04", normal = "plate04_n" }, -- Blue on White 2
    [4] = { diffuse = "yankton_plate", normal = "yankton_plate_n" }, -- North Yankton
    [5] = { diffuse = "epsilon_plate", normal = "epsilon_plate_n" }, -- Epsilon
    [6] = { diffuse = "plate01", normal = "plate01_n" },
    [7] = { diffuse = "plate02", normal = "plate02_n" },
    [8] = { diffuse = "plate03", normal = "plate03_n" },
    [9] = { diffuse = "plate04", normal = "plate04_n" },
    [10] = { diffuse = "plate05", normal = "plate05_n" },
    [11] = { diffuse = "plate06", normal = "plate06_n" },
    [12] = { diffuse = "plate07", normal = "plate07_n" },
}

local loadedDicts = {}
local assignedVehicles = {}

-- Ensure custom texture dictionary is streamed into memory (returns true if available)
local function EnsureDictLoaded(dictName)
    if not dictName or dictName == "" then return false end
    if loadedDicts[dictName] ~= nil then return loadedDicts[dictName] end

    if not HasStreamedTextureDictLoaded(dictName) then
        RequestStreamedTextureDict(dictName, false)
        local timeout = 0
        while not HasStreamedTextureDictLoaded(dictName) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
    end
    local loaded = HasStreamedTextureDictLoaded(dictName)
    loadedDicts[dictName] = loaded
    return loaded
end

-- Determine which dictionary to use for a style based on Config.StateLoreMode
local function GetStyleDict(style)
    if not style then return nil end
    local isLore = Config.StateLoreMode and Config.StateLoreMode[style.state]
    if isLore and style.loreDict and style.loreDict ~= "" then
        return style.loreDict
    end
    return style.realDict
end

-- Helper to get dictionary name for a state
local function GetDefaultDictForState(stateName)
    local clean = stateName:lower():gsub("%s+", "_")
    return clean
end

local function GetDefaultLoreDictForState(stateName)
    if stateName == "New York" then
        return "new_york_lore_liberty"
    end
    return GetDefaultDictForState(stateName) .. "_lore"
end

-- Dynamically initialize and assign slot numbers from Config.Plates
local function InitializeDynamicSlots()

-- Apply custom font color (hex / index) and text placement coordinates to CustomPlates.asi
local function ApplyPlateFontAndExtents(slot, style)
    if not slot or not style then return end

    -- 1. Apply font color (Hex string or numeric index)
    if style.textColor ~= nil then
        pcall(function()
            if type(style.textColor) == "string" then
                -- 0xA1B2C3D400000005: SET_CUSTOM_PLATE_HEX_COLOR (slot, hexString)
                Citizen.InvokeNative(0xA1B2C3D400000005, slot, style.textColor)
            else
                -- 0xA1B2C3D400000002: SET_CUSTOM_PLATE_TEXT_COLOR (slot, colorIndex)
                Citizen.InvokeNative(0xA1B2C3D400000002, slot, style.textColor)
            end
        end)
    end

    -- 2. Apply text placement coordinates / bounding box extents
    if style.fontExtents and type(style.fontExtents) == "table" then
        pcall(function()
            local fe = style.fontExtents
            -- 0xA1B2C3D400000006: SET_CUSTOM_PLATE_EXTENTS (slot, x, y, width, height)
            Citizen.InvokeNative(0xA1B2C3D400000006, slot,
                fe.x or fe[1] or 0.28,
                fe.y or fe[2] or 0.355,
                fe.w or fe.width or fe[3] or 0.816,
                fe.h or fe.height or fe[4] or 0.92
            )
        end)
    end
end

-- Initialize texture replacements for custom plate styles & vanilla slots 0-12
local function SetupTextureReplacements()
    -- 1. Replace custom slots (>= 13) and register font/text color native with CustomPlates.asi
    for slot, style in pairs(CustomPlateStyles) do
        -- Register custom font color and extents with CustomPlates.asi
        ApplyPlateFontAndExtents(slot, style)

        local dict = GetStyleDict(style)
        if dict and style.baseTex and style.diffuse then
            if EnsureDictLoaded(dict) then
                AddReplaceTexture("vehshare", style.baseTex, dict, style.diffuse)
                if style.normal then
                    AddReplaceTexture("vehshare", style.baseTex .. "_n", dict, style.normal)
                end
            end
        end
    end

    -- 2. If configured, replace vanilla slots 0-12 with ServerState plates
    if Config.ReplaceVanillaSlots and Config.ServerState then
        local serverPlates = PlatesByState[Config.ServerState] or {}
        -- Prefer standard/non-gov plates for replacing vanilla passenger plates
        local validPlates = {}
        for _, p in ipairs(serverPlates) do
            if (p.weight or 0) > 0 then
                table.insert(validPlates, p)
            end
        end
        if #validPlates == 0 then
            validPlates = serverPlates
        end

        if #validPlates > 0 then
            for idx = 0, 12 do
                local targetTex = VanillaPlateTextures[idx]
                local repPlate = validPlates[(idx % #validPlates) + 1]
                if targetTex and repPlate then
                    local dict = GetStyleDict(repPlate)
                    if dict and EnsureDictLoaded(dict) then
                        AddReplaceTexture("vehshare", targetTex.diffuse, dict, repPlate.diffuse)
                        if targetTex.normal and repPlate.normal then
                            AddReplaceTexture("vehshare", targetTex.normal, dict, repPlate.normal)
                        end
                    end
                end
            end
        end
    end
end

CreateThread(function()
    SetupTextureReplacements()
end)

-- Apply custom plate index and visual texture to a vehicle
local function ApplyVehiclePlate(veh, slot)
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        return
    end

    local style = CustomPlateStyles[slot]
    if style then
        ApplyPlateFontAndExtents(slot, style)

        local dict = GetStyleDict(style)
        if dict and EnsureDictLoaded(dict) then
            if style.baseTex and style.diffuse then
                AddReplaceTexture("vehshare", style.baseTex, dict, style.diffuse)
                if style.normal then
                    AddReplaceTexture("vehshare", style.baseTex .. "_n", dict, style.normal)
                end
            end
        end
    end

    SetVehicleNumberPlateTextIndex(veh, slot)
end

-- Weighted random selector for custom plates (only plates with weight > 0)
local function RollCustomPlate()
    if not Config.EnablePopulationPlates then return nil end

    local rollPercent = math.random(1, 10000) / 100.0
    if rollPercent > Config.CustomPlateChance then
        return nil
    end

    local serverState = Config.ServerState
    local inStatePlates = {}
    local inStateWeight = 0
    local outOfStatePlates = {}
    local outOfStateWeight = 0

    for _, item in ipairs(AllPlatesList) do
        local weight = item.weight or 0
        -- Skip any plates with weight <= 0 (e.g. Government/Exempt/Police)
        if weight > 0 then
            local isServerState = serverState and (item.state:lower() == serverState:lower())
            local isEnabled = Config.EnabledStates and Config.EnabledStates[item.state]

            if isServerState then
                table.insert(inStatePlates, item)
                inStateWeight = inStateWeight + weight
            elseif isEnabled then
                table.insert(outOfStatePlates, item)
                outOfStateWeight = outOfStateWeight + weight
            end
        end
    end

    -- If server has a specific state and in-state plates exist
    if serverState and #inStatePlates > 0 then
        local ratio = Config.ServerStateRatio or 90.0
        local stateRoll = math.random(1, 10000) / 100.0

        if (stateRoll <= ratio or #outOfStatePlates == 0) and inStateWeight > 0 then
            local roll = math.random(1, inStateWeight)
            local current = 0
            for _, item in ipairs(inStatePlates) do
                current = current + (item.weight or 10)
                if roll <= current then
                    return item.slot
                end
            end
            return inStatePlates[1].slot
        end
    end

    -- Out-of-state travelers
    local candidatePlates = (#outOfStatePlates > 0) and outOfStatePlates or inStatePlates
    local candidateWeight = (#outOfStatePlates > 0) and outOfStateWeight or inStateWeight

    if candidateWeight <= 0 or #candidatePlates == 0 then
        return nil
    end

    local roll = math.random(1, candidateWeight)
    local current = 0
    for _, item in ipairs(candidatePlates) do
        current = current + (item.weight or 10)
        if roll <= current then
            return item.slot
        end
    end

    return candidatePlates[1].slot
end

-- Evaluates an ambient traffic vehicle and rolls for a custom plate if eligible
local function CheckAndAssignPopulationVehicle(veh)
    if not Config.EnablePopulationPlates then return end
    if not DoesEntityExist(veh) then return end
    if assignedVehicles[veh] then return end

    local stateSlot = Entity(veh).state.plateSlot
    if stateSlot ~= nil then
        assignedVehicles[veh] = true
        if stateSlot >= 13 and GetVehicleNumberPlateTextIndex(veh) ~= stateSlot then
            ApplyVehiclePlate(veh, stateSlot)
        end
        return
    end

    if not NetworkHasControlOfEntity(veh) then
        return
    end

    local popType = GetEntityPopulationType(veh)
    local eligible = Config.EligiblePopulationTypes[popType]
    if popType == 0 and Config.AllowUnknownPopulationType then
        eligible = true
    end

    if not eligible then
        assignedVehicles[veh] = true
        return
    end

    assignedVehicles[veh] = true

    local selectedSlot = RollCustomPlate()
    if selectedSlot then
        Entity(veh).state:set("plateSlot", selectedSlot, true)
        ApplyVehiclePlate(veh, selectedSlot)
    end
end

-- State bag change handler
AddStateBagChangeHandler("plateSlot", nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or entity == 0 or not DoesEntityExist(entity) then
        return
    end

    if value >= 13 then
        ApplyVehiclePlate(entity, value)
    elseif value >= 0 and value <= 12 then
        SetVehicleNumberPlateTextIndex(entity, value)
    end
end)

-- Proximity loop for ambient traffic
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)

        local vehicles = GetGamePool("CVehicle")
        for _, veh in ipairs(vehicles) do
            local vCoords = GetEntityCoords(veh)
            local dist = #(pCoords - vCoords)

            if dist < 120.0 then
                CheckAndAssignPopulationVehicle(veh)

                local stateSlot = Entity(veh).state.plateSlot
                if stateSlot and stateSlot >= 13 and GetVehicleNumberPlateTextIndex(veh) ~= stateSlot then
                    ApplyVehiclePlate(veh, stateSlot)
                end
            end
        end
    end
end)

-- ============================================================================
-- Public Client Exports
-- ============================================================================

-- Returns the current server state configured in Config.ServerState
exports("GetServerState", function()
    return Config.ServerState
end)

-- Sets the server state dynamically at runtime and reapplies replacements
exports("SetServerState", function(state)
    Config.ServerState = state
    SetupTextureReplacements()
    return true
end)

-- Returns the full array of all registered plates with their slot numbers, names, and states
exports("GetAllPlates", function()
    return AllPlatesList
end)

-- Returns plate information for a specific slot number (or nil if invalid)
exports("GetPlateBySlot", function(slot)
    return PlatesBySlot[tonumber(slot)]
end)

-- Returns plate information by exact or case-insensitive plate name
exports("GetPlateByName", function(name)
    if not name then return nil end
    return PlatesByName[name:lower()]
end)

-- Returns all plate entries for a specific state (e.g. 'Oregon', 'California')
exports("GetPlatesByState", function(state)
    return PlatesByState[state] or {}
end)

-- Returns a key-value map of { [slot] = "Plate Name" }
-- Sets the font text color index for a specific custom plate slot
-- Indices: 5 = Black, 11 = White, 1 = Yellow, 0 = Blue, 6 = Red, 10 = Green
-- Sets the font text color using any Hex string (e.g. "#FFD700", "#080808", "white") or numeric index
exports("SetCustomPlateHexColor", function(slot, hexColor)
    slot = tonumber(slot)
    if not slot or not hexColor then return false end
    if CustomPlateStyles[slot] then
        CustomPlateStyles[slot].textColor = hexColor
    end
    pcall(function()
        Citizen.InvokeNative(0xA1B2C3D400000005, slot, hexColor)
    end)
    return true
end)

-- Sets custom text placement coordinates / bounding box (x, y, width, height)
exports("SetCustomPlateExtents", function(slot, x, y, width, height)
    slot = tonumber(slot)
    if not slot then return false end
    if CustomPlateStyles[slot] then
        CustomPlateStyles[slot].fontExtents = { x = x, y = y, w = width, h = height }
    end
    pcall(function()
        Citizen.InvokeNative(0xA1B2C3D400000006, slot, x, y, width, height)
    end)
    return true
end)

-- Sets both hex color and extents in a single call
exports("SetCustomPlateProperties", function(slot, hexColor, x, y, width, height)
    slot = tonumber(slot)
    if not slot then return false end
    if CustomPlateStyles[slot] then
        CustomPlateStyles[slot].textColor = hexColor
        CustomPlateStyles[slot].fontExtents = { x = x, y = y, w = width, h = height }
    end
    pcall(function()
        Citizen.InvokeNative(0xA1B2C3D400000007, slot, hexColor, x, y, width, height)
    end)
    return true
end)

exports("SetCustomPlateTextColor", function(slot, colorIndex)
    slot = tonumber(slot)
    colorIndex = tonumber(colorIndex)
    if not slot or not colorIndex then return false end
    if CustomPlateStyles[slot] then
        CustomPlateStyles[slot].textColor = colorIndex
    end
    pcall(function()
        Citizen.InvokeNative(0xA1B2C3D400000002, slot, colorIndex)
    end)
    return true
end)

exports("GetPlateNames", function()
    local names = {}
    for slot, plate in pairs(PlatesBySlot) do
        names[slot] = plate.name
    end
    return names
end)

-- Sets vehicle plate slot
exports("SetVehiclePlateSlot", function(veh, slot)
    if not veh or not DoesEntityExist(veh) then return false end
    Entity(veh).state:set("plateSlot", slot, true)
    ApplyVehiclePlate(veh, slot)
    return true
end)

-- Gets vehicle plate slot
exports("GetVehiclePlateSlot", function(veh)
    if not veh or not DoesEntityExist(veh) then return -1 end
    local stateSlot = Entity(veh).state.plateSlot
    if stateSlot ~= nil then
        return stateSlot
    end
    return GetVehicleNumberPlateTextIndex(veh)
end)

-- Commands
RegisterCommand("plate", function(source, args)
    local query = args[1]
    if not query then
        print("^3Usage: /plate <slot index (0-147) OR plate name>^7")
        return
    end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then
        print("^1You must be in a vehicle to use /plate!^7")
        return
    end

    local slot = tonumber(query)
    local plate = nil

    if slot then
        plate = PlatesBySlot[slot]
    else
        local searchName = table.concat(args, " "):lower()
        plate = PlatesByName[searchName]
        if not plate then
            for _, p in ipairs(AllPlatesList) do
                if p.name:lower():find(searchName, 1, true) then
                    plate = p
                    break
                end
            end
        end
        if plate then
            slot = plate.slot
        end
    end

    if not slot then
        print(string.format('^1Plate "%s" not found!^7', query))
        return
    end

    Entity(veh).state:set("plateSlot", slot, true)
    ApplyVehiclePlate(veh, slot)
    local name = plate and (plate.state .. " - " .. plate.name) or ("Slot " .. slot)
    print(string.format("^2[js_InfinityPlates] Applied plate slot %d (%s) to vehicle %d^7", slot, name, veh))
end, false)

RegisterCommand("listplates", function(source, args)
    local stateFilter = args[1]
    print("^2=== Registered Custom Plates ===^7")
    for _, p in ipairs(AllPlatesList) do
        if not stateFilter or p.state:lower() == stateFilter:lower() then
            local tag = (p.weight == 0) and "^1[GOV/NO-POP]^7" or "^2[CIVILIAN]^7"
            print(string.format("^3Slot %d^7 | %s ^2[%s]^7 %s (Tex: %s)", p.slot, tag, p.state, p.name, p.tex))
        end
    end
end, false)

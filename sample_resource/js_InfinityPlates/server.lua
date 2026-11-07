-- js_InfinityPlates / custom_plates_test: Server-Side Sync & Dynamic Slot Management
-- Exposes full plate lists, slot lookups, and OneSync ambient population distribution

local PlatesBySlot = {}
local PlatesByName = {}
local PlatesByState = {}
local AllPlatesList = {}
local assignedEntities = {}

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

local function InitializeDynamicSlots()
    PlatesBySlot = {}
    PlatesByName = {}
    PlatesByState = {}
    AllPlatesList = {}

    local currentSlot = Config.StartingSlotIndex or 13
    local usedSlots = {}

    local flatPlates = {}
    for key, val in pairs(Config.Plates) do
        if type(key) == "string" and type(val) == "table" then
            local stateName = key
            for _, plate in ipairs(val) do
                local copy = {}
                for k, v in pairs(plate) do copy[k] = v end
                copy.state = copy.state or stateName
                copy.realDict = copy.realDict or GetDefaultDictForState(stateName)
                copy.loreDict = copy.loreDict or GetDefaultLoreDictForState(stateName)
                table.insert(flatPlates, copy)
            end
        elseif type(val) == "table" then
            table.insert(flatPlates, val)
        end
    end

    for _, plate in ipairs(flatPlates) do
        if plate.slot and plate.slot >= 13 then
            usedSlots[plate.slot] = true
        end
    end

    for _, plate in ipairs(flatPlates) do
        local slot = plate.slot
        if not slot then
            while usedSlots[currentSlot] do
                currentSlot = currentSlot + 1
            end
            slot = currentSlot
            usedSlots[slot] = true
            currentSlot = currentSlot + 1
        end

        local entry = {
            slot = slot,
            state = plate.state,
            name = plate.name,
            tex = plate.tex,
            diffuse = plate.tex,
            normal = plate.normal or (plate.tex .. "_n"),
            realDict = plate.realDict or GetDefaultDictForState(plate.state),
            loreDict = plate.loreDict or GetDefaultLoreDictForState(plate.state),
            pattern = plate.pattern or "11AAA111",
            textColor = plate.textColor or 5,
            fontExtents = plate.fontExtents,
            weight = plate.weight ~= nil and plate.weight or 50
        }

        PlatesBySlot[slot] = entry
        PlatesByName[plate.name:lower()] = entry
        if not PlatesByState[plate.state] then
            PlatesByState[plate.state] = {}
        end
        table.insert(PlatesByState[plate.state], entry)
        table.insert(AllPlatesList, entry)
    end
end

InitializeDynamicSlots()

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
        -- Skip any plates with weight <= 0 (Government/Exempt/Police)
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

-- Hook entity creation on server (OneSync)
AddEventHandler("entityCreated", function(entity)
    if not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end

    CreateThread(function()
        Wait(200)
        if not DoesEntityExist(entity) then return end
        if assignedEntities[entity] then return end

        local stateSlot = Entity(entity).state.plateSlot
        if stateSlot ~= nil then
            assignedEntities[entity] = true
            return
        end

        local popType = GetEntityPopulationType(entity)
        local eligible = Config.EligiblePopulationTypes[popType]
        if popType == 0 and Config.AllowUnknownPopulationType then
            eligible = true
        end

        if not eligible then
            assignedEntities[entity] = true
            return
        end

        assignedEntities[entity] = true

        local slot = RollCustomPlate()
        if slot then
            Entity(entity).state:set("plateSlot", slot, true)
        end
    end)
end)

AddEventHandler("entityRemoved", function(entity)
    assignedEntities[entity] = nil
end)

-- ============================================================================
-- Public Server Exports
-- ============================================================================

-- Returns the current server state configured in Config.ServerState
exports("GetServerState", function()
    return Config.ServerState
end)

-- Sets the server state dynamically at runtime
exports("SetServerState", function(state)
    Config.ServerState = state
    return true
end)

-- Returns the full array of all registered plates
exports("GetAllPlates", function()
    return AllPlatesList
end)

-- Returns plate information for a specific slot number (or nil if invalid)
exports("GetPlateBySlot", function(slot)
    return PlatesBySlot[tonumber(slot)]
end)

-- Returns plate information by plate name
exports("GetPlateByName", function(name)
    if not name then return nil end
    return PlatesByName[name:lower()]
end)

-- Returns all plates for a specific state
exports("GetPlatesByState", function(state)
    return PlatesByState[state] or {}
end)

-- Returns a key-value dictionary of { [slot] = "Plate Name" }
-- Returns the configured font text color index for a specific custom plate slot
exports("GetCustomPlateTextColor", function(slot)
    local p = PlatesBySlot[tonumber(slot)]
    return p and (p.textColor or 5) or 5
end)

-- Returns the configured text placement coordinates / fontExtents for a specific slot
exports("GetCustomPlateExtents", function(slot)
    local p = PlatesBySlot[tonumber(slot)]
    return p and p.fontExtents or nil
end)

exports("GetPlateNames", function()
    local names = {}
    for slot, plate in pairs(PlatesBySlot) do
        names[slot] = plate.name
    end
    return names
end)

-- Sets vehicle plate slot
exports("SetVehiclePlateSlot", function(entity, slot)
    if not DoesEntityExist(entity) then return false end
    Entity(entity).state:set("plateSlot", slot, true)
    return true
end)

-- Gets vehicle plate slot
exports("GetVehiclePlateSlot", function(entity)
    if not DoesEntityExist(entity) then return -1 end
    return Entity(entity).state.plateSlot or -1
end)

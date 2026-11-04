-- custom_plates_test: Client-Side Custom License Plate System & Sync
-- Supports slots >= 13 with automatic network synchronization across all players

local CustomPlateStyles = {
    [13] = { diffuse = "yankton_plate", normal = "yankton_plate_n", baseTex = "plate01" },
    [14] = { diffuse = "epsilon_plate", normal = "epsilon_plate_n", baseTex = "plate02" },
    [15] = { diffuse = "ca_exempt",     normal = "ca_exempt_n",     baseTex = "plate03" }
}

-- Ensure custom texture dictionary is streamed into memory and texture replacements active
local function EnsureTexturesLoaded()
    if not HasStreamedTextureDictLoaded("custom_plates") then
        RequestStreamedTextureDict("custom_plates", false)
        local timeout = 0
        while not HasStreamedTextureDictLoaded("custom_plates") and timeout < 100 do
            Wait(10)
            timeout = timeout + 1
        end
    end
end

-- Initialize texture replacements for custom plate styles
local function SetupTextureReplacements()
    EnsureTexturesLoaded()
    for slot, style in pairs(CustomPlateStyles) do
        if style.baseTex and style.diffuse then
            AddReplaceTexture('vehshare', style.baseTex, 'custom_plates', style.diffuse)
            if style.normal then
                AddReplaceTexture('vehshare', style.baseTex .. '_n', 'custom_plates', style.normal)
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

    EnsureTexturesLoaded()

    -- Apply plate slot native (handled & unclamped by CustomPlates.asi)
    SetVehicleNumberPlateTextIndex(veh, slot)

    -- If the style has a texture replacement, ensure it's registered
    local style = CustomPlateStyles[slot]
    if style and style.baseTex and style.diffuse then
        AddReplaceTexture('vehshare', style.baseTex, 'custom_plates', style.diffuse)
        if style.normal then
            AddReplaceTexture('vehshare', style.baseTex .. '_n', 'custom_plates', style.normal)
        end
    end
end

-- 1. Sync via OneSync Replicated State Bags
AddStateBagChangeHandler('plateSlot', nil, function(bagName, key, value, _unused, replicated)
    if not value then return end

    -- bagName format: "entity:<netId>"
    local netId = tonumber(bagName:gsub('entity:', ''))
    if not netId then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity and entity ~= 0 and DoesEntityExist(entity) then
        if GetVehicleNumberPlateTextIndex(entity) ~= value then
            ApplyVehiclePlate(entity, value)
        end
    end
end)

-- 2. Direct Network Event fallback
RegisterNetEvent('customplates:syncPlate', function(netId, slot)
    if not netId or not slot then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        ApplyVehiclePlate(veh, slot)
    end
end)

-- 3. Streaming Scope Monitor: Ensures custom plates render when vehicles stream into view
CreateThread(function()
    while true do
        Wait(500)
        local vehicles = GetGamePool('CVehicle')
        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) then
                local slotState = Entity(veh).state.plateSlot
                if slotState and slotState >= 13 then
                    if GetVehicleNumberPlateTextIndex(veh) ~= slotState then
                        ApplyVehiclePlate(veh, slotState)
                    end
                end
            end
        end
    end
end)

-- Command to switch plates on demand: /plate [0-14 | yankton | epsilon]
RegisterCommand('plate', function(source, args)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        print('^1[CustomPlates] Please sit inside a vehicle first!^7')
        return
    end

    local arg = args[1]
    if not arg then
        print('^3Usage: /plate [0-12 | 13 | 14 | yankton | epsilon]^7')
        print(('^3Current plate index: %d^7'):format(GetVehicleNumberPlateTextIndex(veh)))
        return
    end

    local targetSlot = -1
    if arg == "yankton" then
        targetSlot = 13
    elseif arg == "epsilon" then
        targetSlot = 14
    else
        targetSlot = tonumber(arg)
    end

    if targetSlot and targetSlot >= 0 then
        -- 1. Apply locally
        ApplyVehiclePlate(veh, targetSlot)

        -- 2. Sync to network via Replicated State Bag
        Entity(veh).state:set('plateSlot', targetSlot, true)

        -- 3. Broadcast to server event for immediate sync to all players
        local netId = VehToNet(veh)
        if netId and netId ~= 0 then
            TriggerServerEvent('customplates:setPlate', netId, targetSlot)
        end

        print(('^2[CustomPlates] Vehicle plate changed to slot %d (Network synced!)^7'):format(GetVehicleNumberPlateTextIndex(veh)))
    else
        print(('^1[CustomPlates] Invalid slot argument: %s^7'):format(tostring(arg)))
    end
end, false)

-- Automated test suite command
RegisterCommand('testplates', function()
    EnsureTexturesLoaded()

    local totalPlates = GetNumberOfVehicleNumberPlates()
    print(('^2[CustomPlates] Total available plates: %d (Expected >= 8)^7'):format(totalPlates))

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        print('^1[CustomPlates] Please sit inside a vehicle to test!^7')
        return
    end

    -- 1. Test slot 13 (Yankton)
    ApplyVehiclePlate(veh, 13)
    Entity(veh).state:set('plateSlot', 13, true)
    local netId = VehToNet(veh)
    if netId ~= 0 then
        TriggerServerEvent('customplates:setPlate', netId, 13)
    end
    print(('^2[CustomPlates] Set plate to slot 13 (Yankton). Current index: %d (Synced)^7'):format(GetVehicleNumberPlateTextIndex(veh)))

    Wait(1000)

    -- 2. Test slot 14 (Epsilon)
    ApplyVehiclePlate(veh, 14)
    Entity(veh).state:set('plateSlot', 14, true)
    if netId ~= 0 then
        TriggerServerEvent('customplates:setPlate', netId, 14)
    end
    print(('^2[CustomPlates] Set plate to slot 14 (Epsilon). Current index: %d (Synced)^7'):format(GetVehicleNumberPlateTextIndex(veh)))
end, false)

-- Client Exports
exports('SetVehiclePlateSlot', function(veh, slot)
    slot = tonumber(slot)
    if not slot or not DoesEntityExist(veh) then return false end

    ApplyVehiclePlate(veh, slot)
    Entity(veh).state:set('plateSlot', slot, true)
    local netId = VehToNet(veh)
    if netId ~= 0 then
        TriggerServerEvent('customplates:setPlate', netId, slot)
    end
    return true
end)

exports('GetVehiclePlateSlot', function(veh)
    if not DoesEntityExist(veh) then return nil end
    local stateSlot = Entity(veh).state.plateSlot
    if stateSlot then return stateSlot end
    return GetVehicleNumberPlateTextIndex(veh)
end)

print('^2[CustomPlates] custom_plates_test loaded with Multiplayer Sync! Use /plate [13|14|yankton|epsilon] or /testplates.^7')

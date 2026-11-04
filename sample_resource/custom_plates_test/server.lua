-- custom_plates_test: Server-Side Sync & Ambient Traffic Distribution
-- Replicates custom plate slots (>= 13) across OneSync and distributes custom plates into normal population traffic

local processedVehicles = {}

-- Weighted random selector for custom plates
local function RollCustomPlate()
    if not Config.EnablePopulationPlates then return nil end

    -- Roll overall chance (e.g., 3.0 = 3%)
    local rollPercent = math.random(1, 10000) / 100.0
    if rollPercent > Config.CustomPlateChance then
        return nil
    end

    local totalWeight = 0
    for _, item in ipairs(Config.CustomPlates) do
        totalWeight = totalWeight + item.weight
    end

    if totalWeight <= 0 then return nil end

    local roll = math.random(1, totalWeight)
    local current = 0
    for _, item in ipairs(Config.CustomPlates) do
        current = current + item.weight
        if roll <= current then
            return item.slot
        end
    end

    return Config.CustomPlates[1].slot
end

-- Server-side entityCreated handler for ambient population vehicles
AddEventHandler('entityCreated', function(entity)
    if not Config.EnablePopulationPlates then return end
    if not DoesEntityExist(entity) then return end
    if GetEntityType(entity) ~= 2 then return end -- 2 = Vehicle

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId and netId ~= 0 and processedVehicles[netId] then return end

    -- Wait briefly for entity population type and networking to initialize
    SetTimeout(100, function()
        if not DoesEntityExist(entity) then return end

        -- If entity already has a plateSlot assigned, skip
        if Entity(entity).state.plateSlot ~= nil then return end

        local popType = GetEntityPopulationType(entity)
        local isEligible = Config.EligiblePopulationTypes[popType]
        if not isEligible and Config.AllowUnknownPopulationType and popType == 0 then
            isEligible = true
        end

        if isEligible then
            if netId and netId ~= 0 then processedVehicles[netId] = true end

            local chosenSlot = RollCustomPlate()
            if chosenSlot then
                Entity(entity).state:set('plateSlot', chosenSlot, true)
                if netId and netId ~= 0 then
                    TriggerClientEvent('customplates:syncPlate', -1, netId, chosenSlot)
                end
            else
                -- Mark evaluated as vanilla so clients don't re-roll
                Entity(entity).state:set('plateSlot', -1, true)
            end
        end
    end)
end)

AddEventHandler('entityRemoved', function(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    if netId and netId ~= 0 then
        processedVehicles[netId] = nil
    end
end)

-- Event triggered by clients when a vehicle plate is modified
RegisterNetEvent('customplates:setPlate', function(netId, slot)
    local src = source
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(veh) then
        return
    end

    slot = tonumber(slot)
    if not slot then return end

    processedVehicles[netId] = true

    -- Replicate slot onto the entity state bag across the network
    Entity(veh).state:set('plateSlot', slot, true)

    -- Broadcast sync event to all clients
    TriggerClientEvent('customplates:syncPlate', -1, netId, slot)
end)

-- Server export: Set vehicle plate slot
exports('SetVehiclePlateSlot', function(vehicle, slot)
    if not DoesEntityExist(vehicle) then return false end
    slot = tonumber(slot)
    if not slot then return false end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        processedVehicles[netId] = true
    end

    Entity(vehicle).state:set('plateSlot', slot, true)
    if netId and netId ~= 0 then
        TriggerClientEvent('customplates:syncPlate', -1, netId, slot)
    end
    return true
end)

-- Server export: Get vehicle plate slot
exports('GetVehiclePlateSlot', function(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local slot = Entity(vehicle).state.plateSlot
    if slot and slot >= 0 then return slot end
    return nil
end)

print('^2[CustomPlates] Server sync & population traffic module loaded!^7')

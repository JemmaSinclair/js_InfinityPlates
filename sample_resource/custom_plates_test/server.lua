-- custom_plates_test: Server-Side Sync & State Bag Management
-- Replicates custom plate slots (>= 13) across OneSync to all connected clients

RegisterNetEvent('customplates:setPlate', function(netId, slot)
    local src = source
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(veh) then
        return
    end

    slot = tonumber(slot)
    if not slot then return end

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

    Entity(vehicle).state:set('plateSlot', slot, true)
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        TriggerClientEvent('customplates:syncPlate', -1, netId, slot)
    end
    return true
end)

-- Server export: Get vehicle plate slot
exports('GetVehiclePlateSlot', function(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    return Entity(vehicle).state.plateSlot
end)

print('^2[CustomPlates] Server sync module loaded!^7')

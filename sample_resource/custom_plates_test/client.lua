-- Ensure custom texture dictionary is streamed into memory
CreateThread(function()
    RequestStreamedTextureDict("custom_plates", false)
end)

-- Automated test suite command
RegisterCommand('testplates', function()
    if not HasStreamedTextureDictLoaded("custom_plates") then
        RequestStreamedTextureDict("custom_plates", false)
    end

    local totalPlates = GetNumberOfVehicleNumberPlates()
    print(('^2[CustomPlates] Total available plates: %d (Expected >= 8)^7'):format(totalPlates))

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        print('^1[CustomPlates] Please sit inside a vehicle to test!^7')
        return
    end

    -- 1. Test slot 13 (Yankton)
    SetVehicleNumberPlateTextIndex(veh, 13)
    local curIdx = GetVehicleNumberPlateTextIndex(veh)
    print(('^2[CustomPlates] Set plate to slot 13 (Yankton). Current index: %d^7'):format(curIdx))

    -- 2. Test looking up slot 14 by name (Epsilon)
    local slot14 = GetVehicleNumberPlateIndexByName("epsilon_custom")
    print(('^2[CustomPlates] Looked up "epsilon_custom" -> Slot: %d^7'):format(slot14))
    if slot14 ~= -1 then
        SetVehicleNumberPlateTextIndex(veh, slot14)
        print(('^2[CustomPlates] Set plate to slot 14 (Epsilon). Current index: %d^7'):format(GetVehicleNumberPlateTextIndex(veh)))
    end

    -- 3. Test dynamic runtime script registration (adds slot 15+)
    local runtimeSlot = AddVehicleNumberPlateStyle("runtime_exempt", "custom_plates", "ca_exempt", "custom_plates", "ca_exempt_n", "EXEMPT11")
    print(('^2[CustomPlates] Dynamically registered runtime plate -> Slot: %d^7'):format(runtimeSlot))

    if runtimeSlot > 0 then
        SetVehicleNumberPlateTextIndex(veh, runtimeSlot)
        print(('^2[CustomPlates] Applied dynamic runtime slot %d!^7'):format(GetVehicleNumberPlateTextIndex(veh)))
    end
end, false)

-- Convenient command to switch plates on demand: /plate 13, /plate 14, /plate yankton, /plate epsilon
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
        if not HasStreamedTextureDictLoaded("custom_plates") then
            RequestStreamedTextureDict("custom_plates", false)
        end
        SetVehicleNumberPlateTextIndex(veh, targetSlot)
        print(('^2[CustomPlates] Vehicle plate changed to slot %d!^7'):format(GetVehicleNumberPlateTextIndex(veh)))
    else
        print(('^1[CustomPlates] Invalid slot argument: %s^7'):format(tostring(arg)))
    end
end, false)

print('^2[CustomPlates] custom_plates_test loaded! Use /plate [13|14|yankton|epsilon] or /testplates.^7')

local isOpen = false
local solo = false -- true when only the unwrap screen is showing (opened from the inventory)

local function setFocus(on)
    SetNuiFocus(on, on)
end

local function close()
    if not isOpen then return end
    isOpen = false
    solo = false
    setFocus(false)
    SendNUIMessage({ action = 'close' })
end

local function open()
    if isOpen and not solo then return end

    local state = lib.callback.await('bdev_christmas:getState', false)
    if not state then
        lib.notify({ title = 'Christmas', description = 'Could not load the advent calendar.', type = 'error' })
        return
    end

    isOpen = true
    solo = false
    setFocus(true)
    SendNUIMessage({ action = 'open', state = state })
end

--- Asks the server to unwrap one present. When `fromNui` is false (used from
--- the inventory) this also shows the unwrap screen on its own.
local function unwrap(name, slot, fromNui)
    local result = lib.callback.await('bdev_christmas:openPresent', false, name, slot)
        or { ok = false, message = 'No response from the server.' }

    if fromNui then return result end

    if not result.ok then
        lib.notify({ title = 'Christmas', description = result.message, type = 'error' })
        return result
    end

    if not isOpen then
        isOpen = true
        solo = true
        setFocus(true)
    end
    SendNUIMessage({ action = 'unwrap', data = result, solo = solo })
    return result
end

-- ox_inventory calls this when a present is used (see install/items.lua).
-- The present is only removed by the server once the result is saved.
exports('usePresent', function(data, slot)
    if isOpen then return end
    unwrap(data.name, slot and slot.slot, false)
end)

RegisterCommand(Config.Command, open, false)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Open the Christmas advent calendar and your presents')
end)

RegisterNUICallback('close', function(_, cb)
    close()
    cb(1)
end)

RegisterNUICallback('refresh', function(_, cb)
    cb(lib.callback.await('bdev_christmas:getState', false) or false)
end)

RegisterNUICallback('spin', function(data, cb)
    cb(lib.callback.await('bdev_christmas:spin', false, data.day)
        or { ok = false, message = 'No response from the server.' })
end)

RegisterNUICallback('unwrap', function(data, cb)
    cb(unwrap(data.name, nil, true))
end)

RegisterNUICallback('collect', function(data, cb)
    cb(lib.callback.await('bdev_christmas:collect', false, data.id)
        or { ok = false, message = 'No response from the server.' })
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('bdev_christmas:server:loaded')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)

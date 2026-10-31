local Collector = Config.Collector
if not Collector or not Collector.enabled then return end

local IMAGE_PATH = 'nui://ox_inventory/web/images/%s.png'
local RARITY = { common = 'Common', uncommon = 'Uncommon', rare = 'Rare', epic = 'Epic', legendary = 'Legendary' }

local ped

local function money(amount)
    local s = tostring(math.floor(amount))
    local grouped = s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. grouped
end

local function notify(description, kind)
    lib.notify({ title = Collector.label, description = description, type = kind or 'inform' })
end

---------------------------------------------------------------------------
-- Selling
---------------------------------------------------------------------------

local openMenu

local function sell(name, amount)
    local result = lib.callback.await('bdev_christmas:collectorSell', false, name, amount)
        or { ok = false, message = 'No response from the server.' }
    notify(result.message, result.ok and 'success' or 'error')
    if result.ok then openMenu() end
end

local function askAmount(item)
    if item.count == 1 then return sell(item.name, 1) end

    local input = lib.inputDialog(('Sell %s'):format(item.label), {
        {
            type = 'number',
            label = ('How many? (%s each)'):format(money(item.price)),
            default = item.count,
            min = 1,
            max = item.count,
            required = true,
        },
    })
    if input and input[1] then sell(item.name, math.floor(input[1])) end
end

openMenu = function()
    local offer = lib.callback.await('bdev_christmas:collectorOffer', false)
    if not offer or not offer.ok then
        return notify(offer and offer.message or 'No response from the server.', 'error')
    end

    local total, owned = 0, 0
    for _, item in ipairs(offer.items) do
        total += item.price * item.count
        owned += item.count
    end

    local options = {
        {
            title = owned > 0 and ('Sell all ornaments (%s)'):format(money(total)) or 'Sell all ornaments',
            description = owned > 0
                and ('%d ornament%s, paid in %s'):format(owned, owned == 1 and '' or 's', offer.account)
                or 'You don\'t have any ornaments yet. Find them in Christmas presents.',
            icon = 'sack-dollar',
            iconColor = '#e9b955',
            disabled = owned == 0,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Sell all ornaments?',
                    content = ('Sell %d ornament%s for **%s**? Your ornament collection page keeps track of what you found either way.')
                        :format(owned, owned == 1 and '' or 's', money(total)),
                    centered = true,
                    cancel = true,
                })
                if confirm == 'confirm' then sell(nil, nil) end
            end,
        },
    }

    for _, item in ipairs(offer.items) do
        options[#options + 1] = {
            title = item.label,
            description = ('%s · %s each · you have %d'):format(RARITY[item.rarity] or item.rarity, money(item.price), item.count),
            icon = IMAGE_PATH:format(item.name),
            image = IMAGE_PATH:format(item.name),
            disabled = item.count == 0,
            arrow = item.count > 0,
            onSelect = function() askAmount(item) end,
        }
    end

    lib.registerContext({
        id = 'bdev_christmas_collector',
        title = Collector.label,
        options = options,
    })
    lib.showContext('bdev_christmas_collector')
end

---------------------------------------------------------------------------
-- NPC
---------------------------------------------------------------------------

local function spawn()
    if ped and DoesEntityExist(ped) then return end

    local c = Collector.coords
    lib.requestModel(Collector.model)

    -- Snap to the ground in case the configured Z is a little off.
    local z = c.z
    local found, ground = GetGroundZFor_3dCoord(c.x, c.y, c.z + 2.0, false)
    if found then z = ground end

    ped = CreatePed(4, Collector.model, c.x, c.y, z, c.w, false, true)
    SetModelAsNoLongerNeeded(Collector.model)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesWhenInjured(ped, false)

    if Collector.scenario then
        TaskStartScenarioInPlace(ped, Collector.scenario, 0, true)
    end

    exports.ox_target:addLocalEntity(ped, {
        {
            name = 'bdev_christmas_collector',
            icon = 'fa-solid fa-gift',
            label = 'Sell ornaments',
            distance = 2.5,
            onSelect = openMenu,
        },
    })
end

local function despawn()
    if ped and DoesEntityExist(ped) then
        exports.ox_target:removeLocalEntity(ped, 'bdev_christmas_collector')
        DeleteEntity(ped)
    end
    ped = nil
end

lib.points.new({
    coords = Collector.coords.xyz,
    distance = 60.0,
    onEnter = spawn,
    onExit = despawn,
})

if Collector.blip and Collector.blip.enabled then
    CreateThread(function()
        local c = Collector.coords
        local blip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(blip, Collector.blip.sprite or 108)
        SetBlipColour(blip, Collector.blip.color or 1)
        SetBlipScale(blip, Collector.blip.scale or 0.8)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Collector.label)
        EndTextCommandSetBlipName(blip)
    end)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then despawn() end
end)

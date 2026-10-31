local Collector = Config.Collector
if not Collector or not Collector.enabled then return end

local busy = {}

local function label(name)
    local data = exports.ox_inventory:Items(name)
    return data and data.label or name
end

local function money(amount)
    local s = tostring(math.floor(amount))
    local grouped = s:reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
    return '$' .. grouped
end

local function isOpen()
    if not Collector.openMonths then return true end
    local month = tonumber(os.date('%m'))
    for _, m in ipairs(Collector.openMonths) do
        if m == month then return true end
    end
    return false
end

local function nearCollector(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    return #(GetEntityCoords(ped) - Collector.coords.xyz) <= (Collector.maxDistance or 6.0)
end

local function check(src)
    if not exports.qbx_core:GetPlayer(src) then
        return 'Your character is not loaded yet.'
    end
    if not isOpen() then
        return ('The %s is not buying right now. Come back during the holidays.'):format(Collector.label)
    end
    if not nearCollector(src) then
        return ('You need to be next to the %s.'):format(Collector.label)
    end
end

--- Sorted list of everything the Collector buys, with what the player has.
local function offer(src)
    local list = {}
    for name, price in pairs(Collector.prices) do
        local info = Config.Items[name]
        list[#list + 1] = {
            name = name,
            label = label(name),
            price = price,
            rarity = info and info.rarity or 'common',
            count = exports.ox_inventory:Search(src, 'count', name) or 0,
        }
    end
    table.sort(list, function(a, b)
        if a.price ~= b.price then return a.price < b.price end
        return a.name < b.name
    end)
    return list
end

local function pay(src, amount, reason)
    if Collector.account == 'bank' then
        return exports.qbx_core:AddMoney(src, 'bank', amount, reason) ~= false
    end
    return exports.qbx_core:AddMoney(src, 'cash', amount, reason) ~= false
end

--- Sells `amount` of one ornament. Removes first, pays second, and puts the
--- items back if the payment fails.
local function sellOne(src, name, amount)
    local price = Collector.prices[name]
    local have = exports.ox_inventory:Search(src, 'count', name) or 0
    amount = math.min(amount, have)
    if amount < 1 then return 0 end

    if not exports.ox_inventory:RemoveItem(src, name, amount) then
        return 0
    end

    local total = price * amount
    if not pay(src, total, ('christmas-collector-%s'):format(name)) then
        exports.ox_inventory:AddItem(src, name, amount)
        lib.print.warn(('Collector payment failed for %s, returned %dx %s'):format(GetPlayerName(src), amount, name))
        return 0
    end

    lib.print.info(('%s sold %dx %s to the Collector for %s'):format(GetPlayerName(src), amount, name, money(total)))
    return total, amount
end

lib.callback.register('bdev_christmas:collectorOffer', function(src)
    local problem = check(src)
    if problem then return { ok = false, message = problem } end
    return { ok = true, items = offer(src), account = Collector.account }
end)

lib.callback.register('bdev_christmas:collectorSell', function(src, name, amount)
    if busy[src] then return { ok = false, message = 'Slow down!' } end

    local problem = check(src)
    if problem then return { ok = false, message = problem } end

    -- name == nil sells every ornament the player has.
    if name ~= nil and (type(name) ~= 'string' or not Collector.prices[name]) then
        return { ok = false, message = 'The Collector doesn\'t buy that.' }
    end
    amount = tonumber(amount)
    if name and (not amount or amount < 1 or amount % 1 ~= 0) then
        return { ok = false, message = 'Invalid amount.' }
    end

    busy[src] = true
    local ok, total, sold = pcall(function()
        if name then
            local paid, count = sellOne(src, name, amount)
            return paid, count or 0
        end
        local paid, count = 0, 0
        for item in pairs(Collector.prices) do
            local p, c = sellOne(src, item, math.huge)
            paid += p
            count += c or 0
        end
        return paid, count
    end)
    busy[src] = nil

    if not ok then
        lib.print.error(('Collector sale failed for %s: %s'):format(GetPlayerName(src), total))
        return { ok = false, message = 'Something went wrong. Please try again.' }
    end
    if total <= 0 then
        return { ok = false, message = 'You don\'t have any ornaments to sell.' }
    end

    return {
        ok = true,
        message = ('Sold %d ornament%s for %s.'):format(sold, sold == 1 and '' or 's', money(total)),
    }
end)

AddEventHandler('playerDropped', function()
    busy[source] = nil
end)

CreateThread(function()
    for name in pairs(Collector.prices) do
        if not exports.ox_inventory:Items(name) then
            lib.print.warn(('Collector buys "%s" but it does not exist in ox_inventory. See install/items.lua.'):format(name))
        end
    end
end)

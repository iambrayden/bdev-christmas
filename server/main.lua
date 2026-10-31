local TOTAL_DAYS = Config.TotalDays
local RESOURCE = GetCurrentResourceName()

local CLAIMS = 'bdev_christmas_claims'
local UNWRAPS = 'bdev_christmas_unwraps'

local RANK = { common = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5 }

local busy = {}
local welcomed = {}
local itemCache = {}

local PRESENTS = {}
for i, present in ipairs(Config.Presents) do
    present.order = i
    PRESENTS[present.name] = present
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function itemData(name)
    if itemCache[name] == nil then
        itemCache[name] = exports.ox_inventory:Items(name) or false
    end
    return itemCache[name] or nil
end

local function itemLabel(name)
    local data = itemData(name)
    return data and data.label or name
end

local function rankOf(rarity)
    return RANK[rarity] or 1
end

local function chat(target, message)
    TriggerClientEvent('chat:addMessage', target, {
        color = Config.ChatColor,
        multiline = true,
        args = { ('🎄 %s'):format(Config.ChatPrefix), message },
    })
end

local function getIdentifier(src)
    if Config.TrackBy == 'citizenid' then
        local player = exports.qbx_core:GetPlayer(src)
        return player and player.PlayerData.citizenid
    end
    return GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
end

local function getCharName(src)
    local player = exports.qbx_core:GetPlayer(src)
    local info = player and player.PlayerData.charinfo
    if info and info.firstname then
        local name = ('%s %s'):format(info.firstname, info.lastname or ''):gsub('%s+$', '')
        return name
    end
    return GetPlayerName(src)
end

--- Returns year, calendar day index, and phase ('before' | 'active' | 'after').
local function calendarNow()
    local t = os.date('*t')
    local year = Config.Year or t.year

    local index
    if Config.DebugDay then
        index = Config.DebugDay
    else
        -- Compare at noon so daylight saving changes can't shift the day count.
        local todayNoon = os.time({ year = t.year, month = t.month, day = t.day, hour = 12 })
        local startNoon = os.time({ year = year, month = Config.Month, day = 1, hour = 12 })
        index = math.floor((todayNoon - startNoon) / 86400 + 0.5) + 1
    end

    local phase = index < 1 and 'before' or index > TOTAL_DAYS and 'after' or 'active'
    return year, index, phase
end

local function graceDays()
    return math.max(0, Config.GraceDays or 0)
end

local function inWindow(day, index)
    return day <= index and index - day <= graceDays()
end

local function isRunning(index)
    return index >= 1 and index <= TOTAL_DAYS + graceDays()
end

---------------------------------------------------------------------------
-- Cheer: everything ramps from Dec 1 to Christmas Eve
---------------------------------------------------------------------------

local function progress(day)
    if day >= TOTAL_DAYS - 1 or TOTAL_DAYS <= 2 then return 1 end
    return math.max(0, (day - 1) / (TOTAL_DAYS - 2))
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function amountMultiplier(day)
    local m = Config.Intensity.amountMultiplier
    if day == TOTAL_DAYS then return m.christmas or m.finish end
    return lerp(m.start, m.finish, progress(day))
end

local function cheerLevel(day)
    local label = Config.Intensity.levels[1].label
    for _, level in ipairs(Config.Intensity.levels) do
        if day >= level.fromDay then label = level.label end
    end
    return label
end

local function wheelForDay(day)
    if day == TOTAL_DAYS then return Config.ChristmasWheel end

    local t = progress(day)
    local wheel = {}
    for i, segment in ipairs(Config.Wheel) do
        local early = segment.weight or 1
        local late = segment.lateWeight or early
        wheel[i] = { tier = segment.tier, weight = math.floor(lerp(early, late, t) * 100 + 0.5) / 100 }
    end
    return wheel
end

---------------------------------------------------------------------------
-- Rolling
---------------------------------------------------------------------------

local function weightedPick(list)
    local total = 0
    for i = 1, #list do
        total = total + (list[i].weight or 1)
    end

    local roll = math.random() * total
    for i = 1, #list do
        roll = roll - (list[i].weight or 1)
        if roll <= 0 then return i, list[i] end
    end
    return #list, list[#list]
end

local function rarityOf(reward)
    if reward.rarity then return reward.rarity end
    local info = reward.item and Config.Items[reward.item]
    return info and info.rarity or 'common'
end

--- Picks one reward from a list and rolls its amount.
local function rollFrom(rewards, multiplier)
    local _, reward = weightedPick(rewards)
    multiplier = multiplier or 1

    if reward.money then
        local amount = math.random(reward.money.min, reward.money.max) * multiplier
        return { money = math.max(50, math.floor(amount / 50 + 0.5) * 50), rarity = rarityOf(reward) }
    end

    local min = reward.min or 1
    local max = reward.max or min
    local count = math.random(min, max)
    if max > 1 then
        count = math.floor(count * multiplier + 0.5)
    end
    return { item = reward.item, count = count, rarity = rarityOf(reward) }
end

local function rollDoor(day)
    local segmentIndex, segment = weightedPick(wheelForDay(day))
    local reward = rollFrom(Config.Tiers[segment.tier].rewards, amountMultiplier(day))
    reward.tier = segment.tier
    return segmentIndex, reward
end

--- What the client is allowed to see about a reward that has already been rolled.
local function describeReward(reward)
    if not reward then return nil end
    local tier = reward.tier and Config.Tiers[reward.tier]
    local info = { tier = reward.tier, tierLabel = tier and tier.label, rarity = reward.rarity or 'common' }

    if reward.money then
        info.name, info.label, info.count, info.money = 'money', 'Cash', reward.money, true
    else
        info.name = reward.item
        info.label = itemLabel(reward.item)
        info.count = reward.count
    end
    return info
end

local function describeWheel(wheel)
    local segments = {}
    for i = 1, #wheel do
        local tier = Config.Tiers[wheel[i].tier]
        segments[i] = {
            tier = wheel[i].tier,
            label = tier.label,
            art = tier.art,
            color = tier.color,
            weight = wheel[i].weight or 1,
        }
    end
    return segments
end

local function describePresent(name)
    local info = Config.Items[name]
    return { name = name, label = itemLabel(name), rarity = info and info.rarity or 'common' }
end

local function prizeText(info)
    return info.money and ('$%s'):format(info.count) or ('%dx %s'):format(info.count, info.label)
end

---------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------

local function canCarry(src, reward)
    if reward.money then return true end
    return exports.ox_inventory:CanCarryItem(src, reward.item, reward.count) and true or false
end

local function giveReward(src, reason, reward)
    if reward.money then
        return exports.qbx_core:AddMoney(src, 'cash', reward.money, reason) ~= false
    end

    local success, response = exports.ox_inventory:AddItem(src, reward.item, reward.count)
    if not success then
        lib.print.warn(('Failed to give %s x%d to %s (%s): %s'):format(
            reward.item, reward.count, GetPlayerName(src), reason, tostring(response)))
    end
    return success and true or false
end

---------------------------------------------------------------------------
-- Database reads
---------------------------------------------------------------------------

local function getClaims(identifier, year)
    local claims = {}
    local rows = MySQL.query.await(
        ('SELECT `day`, `status`, `segment`, `reward` FROM `%s` WHERE `identifier` = ? AND `year` = ?'):format(CLAIMS),
        { identifier, year }
    ) or {}
    for i = 1, #rows do
        local row = rows[i]
        claims[row.day] = {
            status = row.status,
            segment = row.segment,
            reward = row.reward and json.decode(row.reward),
        }
    end
    return claims
end

local function feedRarities()
    local list = {}
    local min = rankOf(Config.Feed.minRarity)
    for name, rank in pairs(RANK) do
        if rank >= min then list[#list + 1] = name end
    end
    return list
end

local FEED_RARITIES = feedRarities()

local function getFeed(year)
    if #FEED_RARITIES == 0 or (Config.Feed.size or 0) < 1 then return {} end
    local placeholders = ('?,'):rep(#FEED_RARITIES):sub(1, -2)
    local params = { year }
    for i = 1, #FEED_RARITIES do params[#params + 1] = FEED_RARITIES[i] end
    params[#params + 1] = Config.Feed.size

    local rows = MySQL.query.await(
        ('SELECT `charname`, `present`, `reward`, UNIX_TIMESTAMP(`created_at`) AS `at` FROM `%s` WHERE `year` = ? AND `status` = \'claimed\' AND `rarity` IN (%s) ORDER BY `id` DESC LIMIT ?')
            :format(UNWRAPS, placeholders),
        params
    ) or {}

    local feed = {}
    for i = 1, #rows do
        local row = rows[i]
        feed[i] = {
            who = row.charname or 'Someone',
            present = describePresent(row.present),
            reward = describeReward(json.decode(row.reward)),
            at = row.at,
        }
    end
    return feed
end

local function getLeaderboard(year)
    if (Config.Leaderboard or 0) < 1 then return {} end
    return MySQL.query.await(
        ('SELECT MAX(`charname`) AS `who`, COUNT(*) AS `total` FROM `%s` WHERE `year` = ? AND `status` = \'claimed\' GROUP BY `identifier` ORDER BY `total` DESC LIMIT ?')
            :format(UNWRAPS),
        { year, Config.Leaderboard }
    ) or {}
end

local function getPlayerUnwraps(identifier, year)
    local rows = MySQL.query.await(
        ('SELECT `id`, `present`, `item`, `reward`, `status` FROM `%s` WHERE `identifier` = ? AND `year` = ?'):format(UNWRAPS),
        { identifier, year }
    ) or {}

    local opened, pending, found = 0, {}, {}
    for i = 1, #rows do
        local row = rows[i]
        if row.status == 'claimed' then
            opened += 1
            if row.item then found[row.item] = true end
        else
            pending[#pending + 1] = {
                id = row.id,
                present = describePresent(row.present),
                reward = describeReward(json.decode(row.reward)),
            }
        end
    end
    return opened, pending, found
end

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------

local function dayStatus(day, index, claim)
    if claim and claim.status == 'claimed' then return 'claimed' end
    if day > index then return 'locked' end
    if not inWindow(day, index) then return 'missed' end
    return claim and 'pending' or 'available'
end

local function presentCounts(src)
    local list = {}
    for _, present in ipairs(Config.Presents) do
        local count = exports.ox_inventory:Search(src, 'count', present.name) or 0
        local info = describePresent(present.name)
        info.count = count
        list[#list + 1] = info
    end
    return list
end

local function collectionFor(found)
    local list = {}
    for name, info in pairs(Config.Items) do
        if info.collectible then
            list[#list + 1] = { name = name, label = itemLabel(name), rarity = info.rarity, found = found[name] or false }
        end
    end
    table.sort(list, function(a, b)
        if rankOf(a.rarity) ~= rankOf(b.rarity) then return rankOf(a.rarity) < rankOf(b.rarity) end
        return a.name < b.name
    end)
    return list
end

local function buildState(src)
    local identifier = getIdentifier(src)
    if not identifier then return nil end

    local year, index, phase = calendarNow()
    local claims = getClaims(identifier, year)

    local days = {}
    for day = 1, TOTAL_DAYS do
        local claim = claims[day]
        days[day] = {
            day = day,
            status = dayStatus(day, index, claim),
            intensity = day == TOTAL_DAYS and 1 or progress(day),
            cheer = cheerLevel(day),
            wheel = describeWheel(wheelForDay(day)),
            reward = claim and describeReward(claim.reward) or nil,
            segment = claim and claim.segment or nil,
        }
    end

    local nextUnlock
    if not Config.DebugDay and index < TOTAL_DAYS then
        nextUnlock = os.time({ year = year, month = Config.Month, day = math.max(index, 0) + 1, hour = 0 })
    end

    local opened, pending, found = getPlayerUnwraps(identifier, year)

    return {
        serverName = Config.ServerName,
        now = os.time(),
        christmas = os.time({ year = year, month = Config.Month, day = TOTAL_DAYS, hour = 0 }),
        nextUnlock = nextUnlock,
        today = index,
        phase = phase,
        graceDays = graceDays(),
        days = days,
        presents = presentCounts(src),
        pending = pending,
        opened = opened,
        collection = collectionFor(found),
        feed = getFeed(year),
        leaderboard = getLeaderboard(year),
    }
end

local function countOpen(state)
    local count = 0
    for i = 1, #state.days do
        local status = state.days[i].status
        if status == 'available' or status == 'pending' then count += 1 end
    end
    return count
end

---------------------------------------------------------------------------
-- Advent doors
---------------------------------------------------------------------------

local function spin(src, day)
    if not exports.qbx_core:GetPlayer(src) then
        return { ok = false, message = 'Your character is not loaded yet.' }
    end

    local identifier = getIdentifier(src)
    if not identifier then
        return { ok = false, message = 'Could not find your character.' }
    end

    local year, index = calendarNow()
    local claim = getClaims(identifier, year)[day]
    local status = dayStatus(day, index, claim)

    if status ~= 'available' and status ~= 'pending' then
        local reasons = {
            claimed = 'You already opened this door.',
            locked = 'This door has not unlocked yet.',
            missed = 'This door has expired.',
        }
        return { ok = false, message = reasons[status] or 'You cannot open this door.', state = buildState(src) }
    end

    -- Roll once and save it before anything else, so a full inventory never
    -- turns into a free reroll.
    local freshSpin = not claim
    if freshSpin then
        local segment, reward = rollDoor(day)
        local inserted = MySQL.update.await(
            ('INSERT IGNORE INTO `%s` (`identifier`, `year`, `day`, `status`, `segment`, `reward`) VALUES (?, ?, ?, ?, ?, ?)'):format(CLAIMS),
            { identifier, year, day, 'pending', segment, json.encode(reward) }
        )
        if inserted and inserted > 0 then
            claim = { status = 'pending', segment = segment, reward = reward }
        else
            freshSpin = false
            claim = getClaims(identifier, year)[day]
            if not claim or claim.status ~= 'pending' then
                return { ok = false, message = 'You already opened this door.', state = buildState(src) }
            end
        end
    end

    local result = {
        segment = claim.segment,
        reward = describeReward(claim.reward),
        animate = freshSpin,
    }

    if not canCarry(src, claim.reward) then
        result.ok = false
        result.message = 'Your pockets are full! Your prize is saved. Make some room and collect it.'
        result.state = buildState(src)
        return result
    end

    local updated = MySQL.update.await(
        ('UPDATE `%s` SET `status` = ? WHERE `identifier` = ? AND `year` = ? AND `day` = ? AND `status` = ?'):format(CLAIMS),
        { 'claimed', identifier, year, day, 'pending' }
    )
    if not updated or updated < 1 then
        return { ok = false, message = 'You already collected this prize.', state = buildState(src) }
    end

    if not giveReward(src, ('christmas-advent-day-%d'):format(day), claim.reward) then
        MySQL.update.await(
            ('UPDATE `%s` SET `status` = ? WHERE `identifier` = ? AND `year` = ? AND `day` = ?'):format(CLAIMS),
            { 'pending', identifier, year, day }
        )
        result.ok = false
        result.message = 'Something went wrong giving your prize. It is saved, try collecting again.'
        result.state = buildState(src)
        return result
    end

    local prize = prizeText(result.reward)
    lib.print.info(('%s (%s) won %s from door %d'):format(GetPlayerName(src), identifier, prize, day))

    result.ok = true
    result.message = ('You won %s!'):format(prize)
    result.state = buildState(src)
    return result
end

---------------------------------------------------------------------------
-- Presents
---------------------------------------------------------------------------

local function remainingOf(src, name)
    return exports.ox_inventory:Search(src, 'count', name) or 0
end

--- Rolls a present, saves the result as pending and removes the present.
--- The reward is handed over by collect(), after the unwrap animation.
local function openPresent(src, name, slotId)
    local present = PRESENTS[name]
    if not present then
        return { ok = false, message = 'That is not a present.' }
    end
    if not exports.qbx_core:GetPlayer(src) then
        return { ok = false, message = 'Your character is not loaded yet.' }
    end

    local identifier = getIdentifier(src)
    if not identifier then
        return { ok = false, message = 'Could not find your character.' }
    end

    local slot = slotId and exports.ox_inventory:GetSlot(src, slotId)
    if not slot or slot.name ~= name or (slot.count or 0) < 1 then
        slotId = exports.ox_inventory:GetSlotIdWithItem(src, name)
        if not slotId then
            return { ok = false, message = ('You don\'t have a %s.'):format(itemLabel(name)) }
        end
    end

    local reward = rollFrom(present.rewards, 1)

    if not exports.ox_inventory:RemoveItem(src, name, 1, nil, slotId) then
        return { ok = false, message = 'Could not take the present out of your inventory.' }
    end

    local year = calendarNow()
    local id = MySQL.insert.await(
        ('INSERT INTO `%s` (`identifier`, `year`, `charname`, `present`, `item`, `reward`, `rarity`, `status`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'):format(UNWRAPS),
        { identifier, year, getCharName(src), name, reward.item, json.encode(reward), reward.rarity, 'pending' }
    )

    if not id then
        exports.ox_inventory:AddItem(src, name, 1)
        return { ok = false, message = 'Could not save your present. It was put back.' }
    end

    return {
        ok = true,
        id = id,
        present = describePresent(name),
        reward = describeReward(reward),
        remaining = remainingOf(src, name),
    }
end

local function collect(src, id)
    local identifier = getIdentifier(src)
    if not identifier then
        return { ok = false, message = 'Could not find your character.' }
    end

    local row = MySQL.single.await(
        ('SELECT `id`, `present`, `reward`, `rarity`, `status` FROM `%s` WHERE `id` = ? AND `identifier` = ?'):format(UNWRAPS),
        { id, identifier }
    )
    if not row then
        return { ok = false, message = 'That gift could not be found.' }
    end
    if row.status == 'claimed' then
        return { ok = false, message = 'You already collected this gift.', remaining = remainingOf(src, row.present) }
    end

    local reward = json.decode(row.reward)
    local info = describeReward(reward)

    if not canCarry(src, reward) then
        return {
            ok = false,
            full = true,
            message = ('Your pockets are full! Your %s is saved. Make some room and collect it from /%s.')
                :format(info.label, Config.Command),
            remaining = remainingOf(src, row.present),
        }
    end

    local updated = MySQL.update.await(
        ('UPDATE `%s` SET `status` = \'claimed\' WHERE `id` = ? AND `status` = \'pending\''):format(UNWRAPS),
        { id }
    )
    if not updated or updated < 1 then
        return { ok = false, message = 'You already collected this gift.', remaining = remainingOf(src, row.present) }
    end

    if not giveReward(src, ('christmas-present-%s'):format(row.present), reward) then
        MySQL.update.await(('UPDATE `%s` SET `status` = \'pending\' WHERE `id` = ?'):format(UNWRAPS), { id })
        return { ok = false, message = 'Something went wrong giving your gift. It is saved, try again.', remaining = remainingOf(src, row.present) }
    end

    local prize = prizeText(info)
    local presentLabel = itemLabel(row.present)
    lib.print.info(('%s (%s) unwrapped a %s: %s'):format(GetPlayerName(src), identifier, presentLabel, prize))

    if Config.Announce and rankOf(row.rarity) >= rankOf(Config.Announce) then
        chat(-1, ('%s unwrapped a %s and found %s!'):format(getCharName(src), presentLabel, prize))
    end

    return { ok = true, message = ('You got %s!'):format(prize), remaining = remainingOf(src, row.present) }
end

---------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------

local function guarded(src, label, fn, ...)
    if busy[src] then
        return { ok = false, message = 'Slow down!' }
    end
    busy[src] = true
    local success, result = pcall(fn, src, ...)
    busy[src] = nil

    if not success then
        lib.print.error(('%s failed for %s: %s'):format(label, GetPlayerName(src), result))
        return { ok = false, message = 'Something went wrong. Please try again.' }
    end
    return result
end

lib.callback.register('bdev_christmas:getState', function(src)
    return buildState(src)
end)

lib.callback.register('bdev_christmas:spin', function(src, day)
    day = tonumber(day)
    if not day or day % 1 ~= 0 or day < 1 or day > TOTAL_DAYS then
        return { ok = false, message = 'Invalid door.' }
    end
    return guarded(src, ('Spin (door %d)'):format(day), spin, day)
end)

lib.callback.register('bdev_christmas:openPresent', function(src, name, slot)
    if type(name) ~= 'string' or not PRESENTS[name] then
        return { ok = false, message = 'That is not a present.' }
    end
    slot = tonumber(slot)
    return guarded(src, ('Unwrap (%s)'):format(name), openPresent, name, slot)
end)

lib.callback.register('bdev_christmas:collect', function(src, id)
    id = tonumber(id)
    if not id then
        return { ok = false, message = 'Invalid gift.' }
    end
    return guarded(src, ('Collect (#%d)'):format(id), collect, id)
end)

---------------------------------------------------------------------------
-- Chat messages
---------------------------------------------------------------------------

RegisterNetEvent('bdev_christmas:server:loaded', function()
    local src = source
    if not Config.JoinMessage or welcomed[src] then return end
    welcomed[src] = true

    local state = buildState(src)
    if not state then return end
    local cmd = '/' .. Config.Command

    if #state.pending > 0 then
        chat(src, ('You have %d unclaimed gift%s waiting. Type %s to collect.'):format(
            #state.pending, #state.pending == 1 and '' or 's', cmd))
    end

    local _, index = calendarNow()
    if not isRunning(index) then return end

    local open = countOpen(state)
    if open > 0 then
        local yesterday = index > 1 and state.days[index - 1]
        local expiring = yesterday and (yesterday.status == 'available' or yesterday.status == 'pending')
        chat(src, ('Cheer level: %s. You have %d advent door%s to open%s. Type %s!'):format(
            cheerLevel(math.min(index, TOTAL_DAYS)), open, open == 1 and '' or 's',
            expiring and ' (yesterday\'s expires at midnight)' or '', cmd))
    elseif index < TOTAL_DAYS then
        chat(src, ('You opened every door so far. A new one unlocks at midnight. Type %s to see the countdown.'):format(cmd))
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    welcomed[src] = nil
    busy[src] = nil
end)

if Config.Broadcast.enabled then
    CreateThread(function()
        local interval = math.max(1, Config.Broadcast.intervalMinutes) * 60000
        while true do
            Wait(interval)
            local _, index = calendarNow()
            local cmd = '/' .. Config.Command
            if index >= 1 and index < TOTAL_DAYS then
                local left = TOTAL_DAYS - index
                chat(-1, ('%d day%s until Christmas. Cheer level: %s. Today\'s advent door is open, type %s!')
                    :format(left, left == 1 and '' or 's', cheerLevel(index), cmd))
            elseif index == TOTAL_DAYS then
                chat(-1, ('Merry Christmas! Door 25 has the best wheel of the season. Type %s to open it.'):format(cmd))
            elseif isRunning(index) then
                chat(-1, ('Last chance! The Christmas door can still be opened with %s.'):format(cmd))
            end
        end
    end)
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------

local function validateConfig()
    for _, wheelName in ipairs({ 'Wheel', 'ChristmasWheel' }) do
        for i, segment in ipairs(Config[wheelName]) do
            if not Config.Tiers[segment.tier] then
                lib.print.error(('Config.%s segment %d uses unknown tier "%s"'):format(wheelName, i, segment.tier))
            end
        end
    end

    local function checkRewards(where, rewards)
        for _, reward in ipairs(rewards) do
            if reward.item and not itemData(reward.item) then
                lib.print.warn(('%s reward "%s" does not exist in ox_inventory. See install/items.lua.'):format(where, reward.item))
            end
        end
    end

    for tierName, tier in pairs(Config.Tiers) do
        checkRewards(('Tier "%s"'):format(tierName), tier.rewards)
    end

    for _, present in ipairs(Config.Presents) do
        if not itemData(present.name) then
            lib.print.warn(('Present "%s" does not exist in ox_inventory. See install/items.lua.'):format(present.name))
        end
        checkRewards(('Present "%s"'):format(present.name), present.rewards)
    end
end

CreateThread(function()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `identifier` VARCHAR(64) NOT NULL,
            `year` SMALLINT UNSIGNED NOT NULL,
            `day` TINYINT UNSIGNED NOT NULL,
            `status` VARCHAR(10) NOT NULL DEFAULT 'claimed',
            `segment` TINYINT UNSIGNED NULL,
            `reward` LONGTEXT NULL,
            `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`, `year`, `day`)
        )
    ]]):format(CLAIMS))

    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(64) NOT NULL,
            `year` SMALLINT UNSIGNED NOT NULL,
            `charname` VARCHAR(100) NULL,
            `present` VARCHAR(64) NOT NULL,
            `item` VARCHAR(64) NULL,
            `reward` LONGTEXT NOT NULL,
            `rarity` VARCHAR(12) NOT NULL DEFAULT 'common',
            `status` VARCHAR(10) NOT NULL DEFAULT 'pending',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `player` (`identifier`, `year`),
            KEY `feed` (`year`, `status`, `rarity`)
        )
    ]]):format(UNWRAPS))

    validateConfig()

    if Config.DebugDay then
        lib.print.warn(('%s is running with Config.DebugDay = %d. Turn it off on the live server.')
            :format(RESOURCE, Config.DebugDay))
    end
end)

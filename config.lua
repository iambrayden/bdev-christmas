Config = {}

-- Chat command that opens the advent calendar.
Config.Command = 'christmas'

-- Shown above the title in the menu.
Config.ServerName = 'Last Chance Roleplay'

-- Month the calendar runs in (12 = December). Door N unlocks at midnight
-- server time on day N of this month.
Config.Month = 12

-- Number of doors. The last door is the Christmas Day grand spin.
Config.TotalDays = 25

-- Year the claims are tracked under. nil = current year, so the calendar
-- resets automatically next December.
Config.Year = nil

-- How many extra days a door stays open after its own day.
-- 1 = today's door plus yesterday's as a grace period. 0 = today only.
Config.GraceDays = 1

-- 'citizenid' = one calendar per character.
-- 'license'   = one calendar per Rockstar license, shared by all characters.
Config.TrackBy = 'citizenid'

-- Testing only: set to a number (1-25) to pretend it is that day of December.
-- Leave nil on the live server.
Config.DebugDay = nil

-- Chat message shown to a player when their character loads.
Config.JoinMessage = true

-- Chat message broadcast to everyone on an interval.
Config.Broadcast = {
    enabled = true,
    intervalMinutes = 60,
}

Config.ChatPrefix = 'Christmas'
Config.ChatColor = { 214, 40, 59 }

---------------------------------------------------------------------------
-- Rarity
--
-- Every custom item has a rarity. It colours the item in the menu, decides
-- what shows up in the "Recent unwraps" feed, and what gets announced in chat.
---------------------------------------------------------------------------

Config.Items = {
    candy_cane             = { rarity = 'common' },
    hot_chocolate          = { rarity = 'common' },
    gingerbread_man        = { rarity = 'common' },
    sugar_cookie           = { rarity = 'common' },
    eggnog                 = { rarity = 'uncommon' },

    xmas_present           = { rarity = 'common' },
    xmas_present_silver    = { rarity = 'rare' },
    xmas_present_gold      = { rarity = 'epic' },
    xmas_present_northstar = { rarity = 'legendary' },

    ornament_robin         = { rarity = 'rare',      collectible = true },
    ornament_pinecone      = { rarity = 'rare',      collectible = true },
    ornament_nutcracker    = { rarity = 'epic',      collectible = true },
    ornament_snowglobe     = { rarity = 'epic',      collectible = true },
    ornament_sleighbell    = { rarity = 'legendary', collectible = true },
    ornament_star          = { rarity = 'legendary', collectible = true },
}

-- Unwraps at or above this rarity appear in the server-wide "Recent unwraps" feed.
Config.Feed = { minRarity = 'rare', size = 8 }

-- Unwraps at or above this rarity are announced in chat to everyone. nil = off.
Config.Announce = 'legendary'

-- How many players to show on the "Most presents unwrapped" board. 0 = hide.
Config.Leaderboard = 5

---------------------------------------------------------------------------
-- Presents (loot boxes)
--
-- Each present is an ox_inventory item. Using it from the inventory opens the
-- unwrap screen. The server picks one reward from `rewards`, saves it to the
-- database, removes the present and then hands the reward over.
--
-- Reward formats:
--   { item = 'name', min = 1, max = 3, weight = 10 }
--   { money = { min = 500, max = 2000 }, weight = 10, rarity = 'rare' }
-- `weight` is the relative chance inside that present (default 1).
-- An item reward takes its rarity from Config.Items unless you set `rarity`.
-- Presents can contain other presents.
---------------------------------------------------------------------------

Config.Presents = {
    {
        name = 'xmas_present',
        rewards = {
            { item = 'candy_cane',          min = 2, max = 5, weight = 20 },
            { item = 'hot_chocolate',       min = 1, max = 3, weight = 16 },
            { item = 'gingerbread_man',     min = 1, max = 3, weight = 16 },
            { item = 'sugar_cookie',        min = 2, max = 4, weight = 14 },
            { item = 'eggnog',              min = 1, max = 2, weight = 10 },
            { money = { min = 250, max = 1000 },              weight = 12 },
            { item = 'ornament_robin',      min = 1, max = 1, weight = 4 },
            { item = 'ornament_pinecone',   min = 1, max = 1, weight = 4 },
            { item = 'xmas_present_silver', min = 1, max = 1, weight = 2 },
            { item = 'ornament_nutcracker', min = 1, max = 1, weight = 1 },
            { item = 'ornament_snowglobe',  min = 1, max = 1, weight = 1 },
            { item = 'ornament_sleighbell', min = 1, max = 1, weight = 0.2 },
        },
    },
    {
        name = 'xmas_present_silver',
        rewards = {
            { item = 'candy_cane',          min = 4, max = 8, weight = 8 },
            { item = 'hot_chocolate',       min = 2, max = 4, weight = 8 },
            { item = 'xmas_present',        min = 2, max = 3, weight = 10 },
            { money = { min = 1000, max = 3000 },             weight = 15, rarity = 'uncommon' },
            { item = 'ornament_robin',      min = 1, max = 1, weight = 14 },
            { item = 'ornament_pinecone',   min = 1, max = 1, weight = 14 },
            { item = 'ornament_nutcracker', min = 1, max = 1, weight = 8 },
            { item = 'ornament_snowglobe',  min = 1, max = 1, weight = 8 },
            { item = 'xmas_present_gold',   min = 1, max = 1, weight = 4 },
            { item = 'ornament_sleighbell', min = 1, max = 1, weight = 1 },
            { item = 'ornament_star',       min = 1, max = 1, weight = 1 },
        },
    },
    {
        name = 'xmas_present_gold',
        rewards = {
            { money = { min = 3000, max = 7500 },             weight = 15, rarity = 'rare' },
            { item = 'ornament_robin',      min = 1, max = 1, weight = 10 },
            { item = 'ornament_pinecone',   min = 1, max = 1, weight = 10 },
            { item = 'ornament_nutcracker', min = 1, max = 1, weight = 18 },
            { item = 'ornament_snowglobe',  min = 1, max = 1, weight = 18 },
            { item = 'xmas_present_northstar', min = 1, max = 1, weight = 4 },
            { item = 'ornament_sleighbell', min = 1, max = 1, weight = 5 },
            { item = 'ornament_star',       min = 1, max = 1, weight = 5 },
        },
    },
    {
        name = 'xmas_present_northstar',
        rewards = {
            { item = 'ornament_sleighbell', min = 1, max = 1, weight = 2 },
            { item = 'ornament_star',       min = 1, max = 1, weight = 2 },
            { money = { min = 20000, max = 35000 },           weight = 1, rarity = 'legendary' },
        },
    },
}

---------------------------------------------------------------------------
-- Advent wheel tiers
--
-- Each door spins the wheel once. The wheel lands on a segment (which belongs
-- to a tier), then the server picks one random reward from that tier.
-- `art` is the picture drawn on the wheel slice.
---------------------------------------------------------------------------

Config.Tiers = {
    treats = {
        label = 'Treats',
        art = 'candy_cane',
        color = '#c8303f',
        rewards = {
            { item = 'candy_cane',      min = 2, max = 4, weight = 3 },
            { item = 'hot_chocolate',   min = 1, max = 3, weight = 3 },
            { item = 'gingerbread_man', min = 1, max = 3, weight = 3 },
            { item = 'sugar_cookie',    min = 2, max = 4, weight = 3 },
            { item = 'eggnog',          min = 1, max = 2, weight = 2 },
        },
    },

    present = {
        label = 'Present',
        art = 'xmas_present',
        color = '#1d5c48',
        rewards = {
            { item = 'xmas_present', min = 1, max = 2 },
        },
    },

    cash = {
        label = 'Cash',
        art = 'money',
        color = '#2a8c82',
        rewards = {
            { money = { min = 500, max = 2500 } },
        },
    },

    silver = {
        label = 'Silver',
        art = 'xmas_present_silver',
        color = '#7f95a8',
        rewards = {
            { item = 'xmas_present_silver', min = 1, max = 1 },
        },
    },

    gold = {
        label = 'Gilded',
        art = 'xmas_present_gold',
        color = '#d99a2b',
        rewards = {
            { item = 'xmas_present_gold', min = 1, max = 1 },
        },
    },

    jackpot = {
        label = 'North Star',
        art = 'ornament_star',
        color = '#1b2a5a',
        rewards = {
            { item = 'xmas_present_northstar', min = 1, max = 1, weight = 2 },
            { money = { min = 10000, max = 20000 }, weight = 1, rarity = 'legendary' },
        },
    },
}

---------------------------------------------------------------------------
-- Wheels
--
-- Segments go clockwise from the top. A segment's chance is its weight divided
-- by the wheel's total weight, and its slice is drawn at that size, so what
-- players see matches the real odds.
--
-- `weight` is used on Dec 1 and `lateWeight` on Christmas Eve. Days in between
-- slide smoothly, so the wheel gets better every day.
---------------------------------------------------------------------------

-- Doors 1-24.
Config.Wheel = {
    { tier = 'treats',  weight = 18, lateWeight = 10 },
    { tier = 'present', weight = 12, lateWeight = 10 },
    { tier = 'cash',    weight = 8,  lateWeight = 10 },
    { tier = 'treats',  weight = 18, lateWeight = 10 },
    { tier = 'silver',  weight = 5,  lateWeight = 9 },
    { tier = 'present', weight = 12, lateWeight = 10 },
    { tier = 'cash',    weight = 8,  lateWeight = 10 },
    { tier = 'gold',    weight = 2,  lateWeight = 6 },
    { tier = 'treats',  weight = 14, lateWeight = 8 },
    { tier = 'silver',  weight = 5,  lateWeight = 9 },
    { tier = 'jackpot', weight = 1,  lateWeight = 4 },
}

-- Door 25, Christmas Day. Best odds of the season, no treats.
Config.ChristmasWheel = {
    { tier = 'present', weight = 15 },
    { tier = 'silver',  weight = 20 },
    { tier = 'cash',    weight = 20 },
    { tier = 'gold',    weight = 20 },
    { tier = 'jackpot', weight = 10 },
    { tier = 'silver',  weight = 15 },
}

---------------------------------------------------------------------------
-- Cheer: everything ramps up as Christmas gets closer.
---------------------------------------------------------------------------

Config.Intensity = {
    -- Multiplies cash and stack sizes. Dec 1 uses `start`, Christmas Eve uses
    -- `finish`, Christmas Day uses `christmas`. Single items (max = 1) are
    -- never multiplied.
    amountMultiplier = { start = 1.0, finish = 2.0, christmas = 2.5 },

    -- "Cheer level" shown in the menu. Each level starts on `fromDay`.
    levels = {
        { fromDay = 1,  label = 'Frosty' },
        { fromDay = 8,  label = 'Merry' },
        { fromDay = 15, label = 'Jolly' },
        { fromDay = 21, label = 'Festive' },
        { fromDay = 25, label = 'Christmas' },
    },
}

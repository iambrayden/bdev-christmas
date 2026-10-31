--[[
    bdev-christmas items for ox_inventory

    1. Paste everything between the braces below into ox_inventory/data/items.lua
       (inside the big `return { ... }` table).
    2. Copy every PNG in install/images into ox_inventory/web/images.
    3. Restart ox_inventory, then bdev-christmas.

    Presents call the `usePresent` export, which opens the unwrap screen.
    The server removes the present only after the result is saved, so a crash
    or a full inventory never eats a present or gives a free reroll.
]]

return {
    -- Treats ---------------------------------------------------------------

    ['candy_cane'] = {
        label = 'Candy Cane',
        weight = 50,
        stack = true,
        close = true,
        description = 'Peppermint, hooked, a little sticky.',
        client = {
            status = { hunger = 80000 },
            anim = 'eating',
            usetime = 2000,
            notification = 'You crunched a candy cane',
        },
    },

    ['hot_chocolate'] = {
        label = 'Hot Chocolate',
        weight = 250,
        stack = true,
        close = true,
        description = 'Extra marshmallows. Mind the steam.',
        client = {
            status = { thirst = 200000 },
            anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' },
            prop = { model = `p_amb_coffeecup_01`, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0), bone = 28422 },
            usetime = 3500,
            notification = 'You drank a hot chocolate',
        },
    },

    ['gingerbread_man'] = {
        label = 'Gingerbread Man',
        weight = 80,
        stack = true,
        close = true,
        description = 'Run, run, as fast as you can.',
        client = {
            status = { hunger = 150000 },
            anim = 'eating',
            usetime = 2500,
            notification = 'You ate a gingerbread man. Head first.',
        },
    },

    ['sugar_cookie'] = {
        label = 'Frosted Sugar Cookie',
        weight = 60,
        stack = true,
        close = true,
        description = 'Star shaped, pink icing, sprinkles.',
        client = {
            status = { hunger = 120000 },
            anim = 'eating',
            usetime = 2000,
            notification = 'You ate a frosted sugar cookie',
        },
    },

    ['eggnog'] = {
        label = 'Eggnog',
        weight = 300,
        stack = true,
        close = true,
        description = 'Creamy, spiced, topped with nutmeg.',
        client = {
            status = { hunger = 60000, thirst = 200000 },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = { model = `prop_drink_whtwine`, pos = vec3(0.01, -0.01, -0.06), rot = vec3(0.0, 0.0, 0.0) },
            usetime = 3000,
            notification = 'You drank a glass of eggnog',
        },
    },

    -- Presents -------------------------------------------------------------

    ['xmas_present'] = {
        label = 'Wrapped Present',
        weight = 500,
        stack = true,
        close = true,
        description = 'Red paper, green ribbon. Could be anything.',
        client = { export = 'bdev-christmas.usePresent' },
    },

    ['xmas_present_silver'] = {
        label = 'Silver Present',
        weight = 500,
        stack = true,
        close = true,
        description = 'Foil wrapping. Better odds inside.',
        client = { export = 'bdev-christmas.usePresent' },
    },

    ['xmas_present_gold'] = {
        label = 'Gilded Present',
        weight = 500,
        stack = true,
        close = true,
        description = 'Gold leaf wrapping. Almost always an ornament.',
        client = { export = 'bdev-christmas.usePresent' },
    },

    ['xmas_present_northstar'] = {
        label = 'North Star Present',
        weight = 500,
        stack = true,
        close = true,
        description = 'Midnight paper and gold stars. Guaranteed legendary.',
        client = { export = 'bdev-christmas.usePresent' },
    },

    -- Collectible ornaments ------------------------------------------------

    ['ornament_robin'] = {
        label = 'Glass Robin Ornament',
        weight = 100,
        stack = true,
        description = 'Rare. Hand-blown red bauble with a tiny robin.',
    },

    ['ornament_pinecone'] = {
        label = 'Frosted Pinecone Ornament',
        weight = 100,
        stack = true,
        description = 'Rare. Picked from the back of the North Woods.',
    },

    ['ornament_nutcracker'] = {
        label = 'Nutcracker Ornament',
        weight = 150,
        stack = true,
        description = 'Epic. Stands guard over the tree all season.',
    },

    ['ornament_snowglobe'] = {
        label = 'Snow Globe',
        weight = 250,
        stack = true,
        description = 'Epic. Shake it and a tiny village gets a blizzard.',
    },

    ['ornament_sleighbell'] = {
        label = 'Golden Sleigh Bell',
        weight = 100,
        stack = true,
        description = 'Legendary. Fell off the sleigh on a test flight.',
    },

    ['ornament_star'] = {
        label = 'North Star Tree Topper',
        weight = 200,
        stack = true,
        description = 'Legendary. The star that goes on top of the tree.',
    },
}
